% SP_EVALUATE_ROW: compute the basis functions in one row of the mesh.
%
%     sp = sp_evaluate_row (space, msh, rownum, 'option1', value1, ...)
%
% INPUTS:
%     
%     sp:     class defining the space of discrete functions (see sp_bspline_2d)
%     msh:    msh structure containing (in the field msh.qn) the points 
%              along each parametric direction in the parametric 
%              domain at which to evaluate, i.e. quadrature points 
%              or points for visualization
%     rownum: number of the fixed element in the second parametric direction
%    'option', value: additional optional parameters, currently available options are:
%            
%              Name     |   Default value |  Meaning
%           ------------+-----------------+----------------------------------
%            value      |      true       |  compute shape_functions
%            gradient   |      true       |  compute shape_function_gradients
%            hessian    |      false      |  compute shape_function_hessians
%
% OUTPUT:
%
%    sp: struct representing the discrete function space, with the following fields:
%
%    FIELD_NAME      (SIZE)                      DESCRIPTION
%    ncomp           (scalar)                          number of components of the functions of the space (actually, 1)
%    ndof            (scalar)                          total number of degrees of freedom
%    ndof_dir        (1 x 2 vector)                    degrees of freedom along each direction
%    nsh_max         (scalar)                          maximum number of shape functions per element
%    nsh             (1 x msh.nelu vector)             actual number of shape functions per each element
%    connectivity    (nsh_max x msh.nelu vector)       indices of basis functions that do not vanish in each element
%    shape_functions (msh.nqn x nsh_max x msh.nelu)    basis functions evaluated at each quadrature node in each element
%    shape_function_gradients
%                        (2 x msh.nqn x nsh_max x msh.nelu) basis function gradients evaluated at each quadrature node in each element
%    shape_function_hessians
%                        (2 x 2 x msh.nqn x nsh_max x msh.nelu) basis function hessians evaluated at each quadrature node in each element
%
% Copyright (C) 2009, 2010, 2011 Carlo de Falco
% Copyright (C) 2011 Rafael Vazquez
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.

%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.

function [sp, elem_list] = sp_evaluate_row (space, msh, rownum, varargin)

value = true;
gradient = true;
if (~isempty (varargin))
  if (~rem (length (varargin), 2) == 0)
    error ('sp_evaluate_row: options must be passed in the [option, value] format');
  end
  for ii=1:2:length(varargin)-1
    if (strcmpi (varargin {ii}, 'value'))
      value = varargin {ii+1};
    elseif (strcmpi (varargin {ii}, 'gradient'))
      gradient = varargin {ii+1};
    else
      error ('sp_evaluate_row: unknown option %s', varargin {ii});
    end
  end
end

elem_list = msh.nelu * (rownum-1) + (1:msh.nelu);

spu = space.spu;
spv = space.spv;

nsh  = spu.nsh * spv.nsh(rownum)';
nsh  = nsh(:)';
ndof = spu.ndof * spv.ndof;
ndof_dir = [spu.ndof, spv.ndof];

connectivity = space.connectivity(:,elem_list);

shp_u = reshape (spu.shape_functions, msh.nqnu, 1, spu.nsh_max, 1, msh.nelu);
shp_u = repmat  (shp_u, [1, msh.nqnv, 1, spv.nsh_max, 1]);
shp_u = reshape (shp_u, msh.nqn, space.nsh_max, msh.nelu);

shp_v = reshape (spv.shape_functions(:, :, rownum), ...
                 1, msh.nqnv, 1, spv.nsh_max, 1);  %% one row only
shp_v = repmat  (shp_v, [msh.nqnu, 1, spu.nsh_max, 1, msh.nelu]);
shp_v = reshape (shp_v, msh.nqn, space.nsh_max, msh.nelu);

% Multiply each function by the weight and compute the denominator
W = space.weights (connectivity);
W = repmat (reshape (W, 1, space.nsh_max, msh.nelu), [msh.nqn, 1, 1]);
shape_functions = W.* shp_u .* shp_v ;
D = repmat (reshape (sum (shape_functions, 2), msh.nqn, 1, msh.nelu), [1, space.nsh_max, 1]);
shape_functions = shape_functions ./ D;

sp = struct('nsh_max', space.nsh_max, 'nsh', nsh, 'ndof', ndof,  ...
            'ndof_dir', ndof_dir, 'connectivity', connectivity, ...
            'ncomp', 1);
if (value)
  sp.shape_functions = shape_functions;
end

if (gradient)
  shg_u = reshape (spu.shape_function_gradients, ...
                   msh.nqnu, 1, spu.nsh_max, 1, msh.nelu);
  shg_u = repmat  (shg_u, [1, msh.nqnv, 1, spv.nsh_max, 1]);
  shg_u = reshape (shg_u, msh.nqn, space.nsh_max, msh.nelu);
  
  shg_v = reshape (spv.shape_function_gradients(:,:,rownum), ...
                   1, msh.nqnv, 1, spv.nsh_max, 1); %% one row only
  shg_v = repmat  (shg_v, [msh.nqnu, 1, spu.nsh_max, 1, msh.nelu]);
  shg_v = reshape (shg_v, msh.nqn, space.nsh_max, msh.nelu);
  
  Bu = W .* shg_u .* shp_v;
  Bv = W .* shp_u .* shg_v;

  Du = repmat (reshape (sum (Bu, 2), msh.nqn, 1, msh.nelu), [1, sp.nsh_max, 1]);
  Dv = repmat (reshape (sum (Bv, 2), msh.nqn, 1, msh.nelu), [1, sp.nsh_max, 1]);

  shape_fun_grads(1,:,:,:) = (Bu - shape_functions .* Du)./D;
  shape_fun_grads(2,:,:,:) = (Bv - shape_functions .* Dv)./D;

  JinvT = geopdes_invT__ (msh.geo_map_jac(:,:,:,elem_list));
  JinvT = reshape (JinvT, [2, 2, msh.nqn, msh.nelu]);
  shape_fun_grads = reshape (shape_fun_grads, ...
                            [2, msh.nqn, sp.nsh_max, msh.nelu]);
  sp.shape_function_gradients = geopdes_prod__ (JinvT, shape_fun_grads);

  clear shg_u shg_v shape_fun_grads Bu Bv Du Dv
end

clear shp_u shp_v

end
