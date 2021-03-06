% EX_KIRCHHOFF_RECTANGULAR_PLATE_CLAMPED: solve bilaplacian in a clamped rectangular plate.

% PHYSICAL DATA OF THE PROBLEM
clear problem_data
% Geometry definition (unrefined geometry)
base = 1; height = 1;
p11 =[0 0]; p12 =[base 0]; p21 =[0 height]; p22 =[base height];
srf = nrb4surf (p11,p12,p21,p22);

problem_data.geo_name = srf;

% Elasticity constants
E  =  30;                         % Young modulus   
nu = 0.3;                         % Poisson modulus
tr = 0.2;                         % Thickness of the plate
D  = E*tr*tr*tr/(12*(1-nu*nu));   % Flexural rigidity of the plate
p = -1;                           % Distributed load

% Boundary conditions
problem_data.simply_supported_sides = [];
problem_data.clamped_sides = [1 2 3 4];

% Physical parameters
problem_data.c_diff  = @(x, y) D*ones(size(x));
% Source term
problem_data.f = @(x, y) p*ones(size(x));

% CHOICE OF THE DISCRETIZATION PARAMETERS
%clear method_data
method_data.degree     = [3 3];  % Degree of the splines
method_data.regularity = [2 2];  % Regularity of the splines
method_data.nsub       = [9 9];  % Number of subdivisions
method_data.nquad      = [4 4];  % Points for the Gaussian quadrature rule

% CALL TO THE SOLVER
[geometry, msh, space, u] = ...
    solve_bilaplace_gradgrad_2d_iso (problem_data, method_data);

% POST-PROCESSING
% EXPORT TO PARAVIEW
output_file = 'Kirchhoff_Rectangular_Plate_Clamped';
vtk_pts = {linspace(0, 1, 31), linspace(0, 1, 31)};
fprintf ('The result is saved in the file %s \n \n', output_file);
sp_to_vtk (u, space, geometry, vtk_pts, output_file, 'u')

% % PLOT IN MATLAB
% Plot of the refined geometry and control points, and of the computational mesh
% figure
% nrbctrlplot (geometry.nurbs)
% figure
% nrbkntplot (geometry.nurbs)

% % Plot of the computed solution
figure
sp_plot_solution (u, space, geometry, vtk_pts)
title ('Numerical solution')
axis equal

% Max Deflection (in the same points used for plotting)
max_displacement = min (eu(:));
fprintf ('Computed solution, max. displacement = %e \n', max_displacement);
