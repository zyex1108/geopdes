% EX_LAPLACE_EIG_SQUARE: Compute eigenvalues and eigenvectors for the Laplace operator in the square.
%
% 1) PHYSICAL DATA OF THE PROBLEM
clear problem_data 
% Physical domain, defined as NURBS map given in a text file
problem_data.geo_name = 'geo_square.txt';

% Type of boundary conditions
problem_data.nmnn_sides   = [];
problem_data.drchlt_sides = [1 2 3 4];

% Physical parameters
problem_data.c_diff = @(x, y) ones(size(x));
problem_data.c_mass = @(x, y) ones(size(x));

% 2) CHOICE OF THE DISCRETIZATION PARAMETERS
clear method_data
method_data.degree     = [3 3];     % Degree of the bsplines
method_data.regularity = [2 2];     % Regularity of the splines
method_data.nsub       = [8 8];     % Number of subdivisions
method_data.nquad      = [4 4];     % Points for the Gaussian quadrature rule

% 3) CALL TO THE SOLVER

[geometry, msh, space, lambda, u] = ...
                 solve_laplace_eig (problem_data, method_data);

% 4) POST-PROCESSING

if (all (imag (lambda) == 0))
  [lambda, perm] = sort (lambda);
elseif (any (abs (imag (lambda)) > 1e-9))
  error ('Complex eigenvalues appeared. I skip the postprocess.')
else
  warning ('Complex eigenvalues appeared, with small imaginary part. Only the real part is used for postprocessing')
  [lambda, perm] = sort (real (lambda));
end

% Plot of the 11th eigenfunction
figure
subplot(1,2,1)
sp_plot_solution (u(:,perm(11)), space, geometry, [31 31]);
title ('Plot of the 11^{th} eigenfunction')

% Comparison with the exact eigenvalues
ndofs_1 = repmat ([1:space.ndof_dir(1)-2], space.ndof_dir(2)-2, 1);
ndofs_2 = repmat ([1:space.ndof_dir(2)-2]', 1, space.ndof_dir(1)-2);
exact = pi * sqrt (ndofs_1.^2 + ndofs_2.^2);
exact = sort (exact(:));
spectrum = sqrt (lambda) ./ exact;
subplot(1,2,2)
plot (linspace (0, 1, numel (spectrum)), spectrum, '*')
title ('Ratio of numerical to exact eigenvalues')

%!demo
%! ex_laplace_eig_square

%!test
%! problem_data.geo_name = 'geo_square.txt';
%! problem_data.nmnn_sides   = [];
%! problem_data.drchlt_sides = [1 2 3 4];
%! problem_data.c_diff = @(x, y) ones(size(x));
%! problem_data.c_mass = @(x, y) ones(size(x));
%! method_data.degree     = [3 3];     % Degree of the bsplines
%! method_data.regularity = [2 2];     % Regularity of the splines
%! method_data.nsub       = [8 8];     % Number of subdivisions
%! method_data.nquad      = [4 4];     % Points for the Gaussian quadrature rule
%! [geometry, msh, space, lambda, u] = ...
%!                  solve_laplace_eig (problem_data, method_data);
%! [lambda, perm] = sort (lambda);
%! assert (msh.nel, 64);
%! assert (space.ndof, 121);
%! assert (lambda(1:6)/pi^2, [2.00000025982960, 5.00004032992316, 5.00004032992316, 8.00008040001672, 10.00134779087585, 10.00134779087586]', 5e-13)
