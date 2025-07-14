function [V] = panelling(V,n_seg_max)

% clc;
% close all;
% % rad=0.5;
min_seg=0.02;
max_seg=0.06;
if nargin < 2
    n_seg_max=200;
end
% % n_init=80;

% V=readmatrix(sprintf('./BaseShapes/2.txt'));
x=transpose(V(:,1));
y=transpose(V(:,2));
% plot(x,y,'.')
% hold on

rep_check=V(2:end,1)-V(1:end-1,1);
rep_ind=find(abs(rep_check)<10^-4);
V(rep_ind+1,:)=[];
[~,seglen] = arclength(V(:,1),V(:,2),'spline');

seglen=seglen(2:end)+seglen(1:end-1);
%  || length(seglen)>=n_seg_max
  counter_break=0;
while counter_break<5000
counter_break=counter_break+1;
[M,ind]=min(seglen);
if M<=min_seg
    if ind==1
    seglen(ind+1)=seglen(ind)+seglen(ind+1);
    if seglen(ind+1)>max_seg
        break
    end
    elseif ind==length(seglen)
    seglen(ind-1)=seglen(ind)+seglen(ind-1);
    if seglen(ind-1)>max_seg
        break
    end
    else
    seglen(ind+1)=seglen(ind)+seglen(ind+1);
    seglen(ind-1)=seglen(ind)+seglen(ind-1);
    if seglen(ind+1)>max_seg || seglen(ind-1)>max_seg
        break
    end
    end
    V(ind+1,:)=[];
    seglen(ind)=[];
%     [arclen,seglen] = arclength(V(:,1),V(:,2),'spline');
    continue
end
break
end
if counter_break==5000
      disp(counter_break)
end
k=LineCurvature2D(V);
k=k(2:end-1);
% [arclen,seglen] = arclength(V(:,1),V(:,2),'spline');
[~,seglen] = arclength(V(:,1),V(:,2),'spline');
seglen=seglen(2:end)+seglen(1:end-1);
v_1=V(1,:);
v_2=V(end,:);
V=V(2:end-1,:);
counter_break=0;
while counter_break<=10000
counter_break=counter_break+1;
% [M,ind]=min(k);
[~,ind]=min(k);
if all(k == k(1))
    break
end
if length(k)>n_seg_max

    if ind==1
    if seglen(ind)+seglen(ind+1)>max_seg
        k(ind)=1000;
        continue
    end
    seglen(ind+1)=seglen(ind)+seglen(ind+1);
    elseif ind==length(k)
    if seglen(ind)+seglen(ind-1)>max_seg
        k(ind)=1000;
        continue
    end
    seglen(ind-1)=seglen(ind)+seglen(ind-1);
    else
    if seglen(ind)+seglen(ind+1)>max_seg && seglen(ind)+seglen(ind-1)>max_seg
        k(ind)=1000;
        continue
    end
    seglen(ind+1)=seglen(ind)+seglen(ind+1);
    seglen(ind-1)=seglen(ind)+seglen(ind-1);
    end
    
    seglen(ind)=[];
    V(ind,:)=[];
    k(ind)=[];
    continue
end
break
end
V=[v_1;V;v_2];
V(:,1)=smooth(V(:,1),5);
V(:,2)=smooth(V(:,2),5);
if counter_break==10000
      disp(counter_break)
end

% plot(V(:,1),V(:,2),'*')
% hold on
% ylim([-1 1])

end

%% Generate pseudo-data
% npoints=20;
% x=linspace(0,1,npoints);
% x=[fliplr(x(2:end)) x(1:end-1) ];
% y=rand(1,length(x));
% y = smoothdata(y,'gaussian',15);
% plot(x,y)
% hold on
% if numel(V(:,1))>n_init %495 is the max num of panel nodes allowed in XFOIL 
%     V_undersampled = V(1:ceil(numel(V(:,1))/n_init):end,:);
% else
%     V_undersampled = V;
% end
% x=transpose(V_undersampled(:,1));
% y=transpose(V_undersampled(:,2));
% x=transpose(V(:,1));
% y=transpose(V(:,2));
% plot(x,y,'.')
% hold on
% 
% [arclen,seglen] = arclength(V(:,1),V(:,2),'spline');
% k=LineCurvature2D(V);

% %% Massage data
% % Remove duplicates
% dist=[1 (x(2:end)-x(1:end-1)).^2];
% x(dist < 10^-12) = [];
% y(dist < 10^-12) = [];
% spline_list = {};
% count=1;
% flag=-1;
% for i=2:length(x)
%     if (x(i)>x(i-1) && flag<0) || (x(i)<x(i-1) && flag>0)
%         spline_list{end+1}=spline(x(count:i-1),y(count:i-1));
% %         v_1=transpose([x(count:i-1);y(count:i-1)]);
%         count=i-1;
%         flag=flag*-1;
%     end
% end
% spline_list{end+1}=spline(x(count:i-1),y(count:i-1));
% % v_2=transpose([x(count:i-1);y(count:i-1)]);
% [arclen,seglen] = arclength(x,y,'spline');
% max_seg=arclen/n_seg;
% Vertices=transpose([x;y]);
% k=LineCurvature2D(Vertices);
% flag=0;
% while flag==0
%     for i=1:size(Vertices,1)-1
% %         if (abs(k(i+1))<rad && seglen(i)>=min_seg) || seglen(i)>=max_seg
%         if seglen(i)>=max_seg
%             if i<=count
%                s_ind=1;
%                count=count+1;
%             else
%                s_ind=2;
%             end
%             new_x=(Vertices(i,1)+Vertices(i+1,1))/2;
%             new_y = ppval(spline_list{s_ind}, (Vertices(i,1)+Vertices(i+1,1))/2);
%             Vertices=[Vertices(1:i,:);[new_x new_y];Vertices(i+1:end,:)];
%             plot(new_x,new_y,'*')
%             hold on
%             [arclen,seglen] = arclength(Vertices(:,1),Vertices(:,2),'spline');
%             k=LineCurvature2D(Vertices);
%             break;
%         end
%         
%         if i==size(Vertices,1)-1
%             flag=1;
%         end
%     end
% end

%% LOCAL SUBROUTINES
function [arclen,seglen] = arclength(px,py,varargin)
% arclength: compute arc length of a space curve, or any curve represented as a sequence of points
% usage: [arclen,seglen] = arclength(px,py)         % a 2-d curve
% usage: [arclen,seglen] = arclength(px,py,pz)      % a 3-d space curve
% usage: [arclen,seglen] = arclength(px,py,method)  % specifies the method used
%
% Computes the arc length of a function or any
% general 2-d, 3-d or higher dimensional space
% curve using various methods.
%
% arguments: (input)
%  px, py, pz, ... - vectors of length n, defining points
%        along the curve. n must be at least 2. Replicate
%        points should not be present in the curve.
%
%  method - (OPTIONAL) string flag - denotes the method
%        used to compute the arc length of the curve.
%
%        method may be any of 'linear', 'spline', or 'pchip',
%        or any simple contraction thereof, such as 'lin',
%        'sp', or even 'p'.
%        
%        method == 'linear' --> Uses a linear chordal
%               approximation to compute the arc length.
%               This method is the most efficient.
%
%        method == 'pchip' --> Fits a parametric pchip
%               approximation, then integrates the
%               segments numerically.
%
%        method == 'spline' --> Uses a parametric spline
%               approximation to fit the curves, then
%               integrates the segments numerically.
%               Generally for a smooth curve, this
%               method may be most accurate.
%
%        DEFAULT: 'linear'
%
%
% arguments: (output)
%  arclen - scalar total arclength of all curve segments
%
%  seglen - arclength of each independent curve segment
%           there will be n-1 segments for which the
%           arc length will be computed.
%
%
% Example:
% % Compute the length of the perimeter of a unit circle
% theta = linspace(0,2*pi,10);
% x = cos(theta);
% y = sin(theta);
%
% % The exact value is
% 2*pi
% % ans =
% %          6.28318530717959
%
% % linear chord lengths
% arclen = arclength(x,y,'l')
% % arclen =
% %           6.1564
%
% % Integrated pchip curve fit
% arclen = arclength(x,y,'p')
% % arclen =
% %          6.2782
%
% % Integrated spline fit
% arclen = arclength(x,y,'s')
% % arclen =
% %           6.2856
%
% Example:
% % A (linear) space curve in 5 dimensions
% x = 0:.25:1;
% y = x;
% z = x;
% u = x;
% v = x;
%
% % The length of this curve is simply sqrt(5)
% % since the "curve" is merely the diagonal of a
% % unit 5 dimensional hyper-cube.
% [arclen,seglen] = arclength(x,y,z,u,v,'l')
% % arclen =
% %           2.23606797749979
% % seglen =
% %         0.559016994374947
% %         0.559016994374947
% %         0.559016994374947
% %         0.559016994374947
%
%
% See also: interparc, spline, pchip, interp1
%
% Author: John D'Errico
% e-mail: woodchips@rochester.rr.com
% Release: 1.0
% Release date: 3/10/2010

% unpack the arguments and check for errors
if nargin < 2
  error('ARCLENGTH:insufficientarguments', ...
    'at least px and py must be supplied')
end

n = length(px);
% are px and py both vectors of the same length?
if ~isvector(px) || ~isvector(py) || (length(py) ~= n)
  error('ARCLENGTH:improperpxorpy', ...
    'px and py must be vectors of the same length')
elseif n < 2
  error('ARCLENGTH:improperpxorpy', ...
    'px and py must be vectors of length at least 2')
end

% compile the curve into one array
data = [px(:),py(:)];

% defaults for method and tol
method = 'linear';

% which other arguments are included in varargin?
if numel(varargin) > 0
  % at least one other argument was supplied
  for i = 1:numel(varargin)
    arg = varargin{i};
    if ischar(arg)
      % it must be the method
      validmethods = {'linear' 'pchip' 'spline'};
      ind = strmatch(lower(arg),validmethods);
      if isempty(ind) || (length(ind) > 1)
        error('ARCLENGTH:invalidmethod', ...
          'Invalid method indicated. Only ''linear'',''pchip'',''spline'' allowed.')
      end
      method = validmethods{ind};
      
    else
      % it must be pz, defining a space curve in higher dimensions
      if numel(arg) ~= n
        error('ARCLENGTH:inconsistentpz', ...
          'pz was supplied, but is inconsistent in size with px and py')
      end
      
      % expand the data array to be a 3-d space curve
      data = [data,arg(:)]; %#ok
    end
  end
  
end

% what dimension do we live in?
nd = size(data,2);

% compute the chordal linear arclengths
seglen = sqrt(sum(diff(data,[],1).^2,2));
arclen = sum(seglen);

% we can quit if the method was 'linear'.
if strcmpi(method,'linear')
  % we are now done. just exit
  return
end

% 'spline' or 'pchip' must have been indicated,
% so we will be doing an integration. Save the
% linear chord lengths for later use.
chordlen = seglen;

% compute the splines
spl = cell(1,nd);
spld = spl;
diffarray = [3 0 0;0 2 0;0 0 1;0 0 0];
for i = 1:nd
  switch method
    case 'pchip'
      spl{i} = pchip([0;cumsum(chordlen)],data(:,i));
    case 'spline'
      spl{i} = spline([0;cumsum(chordlen)],data(:,i));
      nc = numel(spl{i}.coefs);
      if nc < 4
        % just pretend it has cubic segments
        spl{i}.coefs = [zeros(1,4-nc),spl{i}.coefs];
        spl{i}.order = 4;
      end
  end
  
  % and now differentiate them
  xp = spl{i};
  xp.coefs = xp.coefs*diffarray;
  xp.order = 3;
  spld{i} = xp;
end

% numerical integration along the curve
polyarray = zeros(nd,3);
for i = 1:spl{1}.pieces
  % extract polynomials for the derivatives
  for j = 1:nd
    polyarray(j,:) = spld{j}.coefs(i,:);
  end
  
  % integrate the arclength for the i'th segment
  % using quadgk for the integral. I could have
  % done this part with an ode solver too.
  seglen(i) = quadgk(@(t) segkernel(t),0,chordlen(i));
end

% and sum the segments
arclen = sum(seglen);

% ==========================
%   end main function
% ==========================
%   begin nested functions
% ==========================
  function val = segkernel(t)
    % sqrt((dx/dt)^2 + (dy/dt)^2)
    
    val = zeros(size(t));
    for k = 1:nd
      val = val + polyval(polyarray(k,:),t).^2;
    end
    val = sqrt(val);
    
  end % function segkernel

end % function arclength

function k=LineCurvature2D(Vertices,Lines)
% This function calculates the curvature of a 2D line. It first fits 
% polygons to the points. Then calculates the analytical curvature from
% the polygons;
%
%  k = LineCurvature2D(Vertices,Lines)
% 
% inputs,
%   Vertices : A M x 2 list of line points.
%   (optional)
%   Lines : A N x 2 list of line pieces, by indices of the vertices
%         (if not set assume Lines=[1 2; 2 3 ; ... ; M-1 M])
%
% outputs,
%   k : M x 1 Curvature values
%
%
%
% Example, Circle
%  r=sort(rand(15,1))*2*pi;
%  Vertices=[sin(r) cos(r)]*10;
%  Lines=[(1:size(Vertices,1))' (2:size(Vertices,1)+1)']; Lines(end,2)=1;
%  k=LineCurvature2D(Vertices,Lines);
%
%  figure,  hold on;
%  N=LineNormals2D(Vertices,Lines);
%  k=k*100;
%  plot([Vertices(:,1) Vertices(:,1)+k.*N(:,1)]',[Vertices(:,2) Vertices(:,2)+k.*N(:,2)]','g');
%  plot([Vertices(Lines(:,1),1) Vertices(Lines(:,2),1)]',[Vertices(Lines(:,1),2) Vertices(Lines(:,2),2)]','b');
%  plot(sin(0:0.01:2*pi)*10,cos(0:0.01:2*pi)*10,'r.');
%  axis equal;
%
% Example, Hand
%  load('testdata');
%  k=LineCurvature2D(Vertices,Lines);
%
%  figure,  hold on;
%  N=LineNormals2D(Vertices,Lines);
%  k=k*100;
%  plot([Vertices(:,1) Vertices(:,1)+k.*N(:,1)]',[Vertices(:,2) Vertices(:,2)+k.*N(:,2)]','g');
%  plot([Vertices(Lines(:,1),1) Vertices(Lines(:,2),1)]',[Vertices(Lines(:,1),2) Vertices(Lines(:,2),2)]','b');
%  plot(Vertices(:,1),Vertices(:,2),'r.');
%  axis equal;
%
% Function is written by D.Kroon University of Twente (August 2011)

% If no line-indices, assume a x(1) connected with x(2), x(3) with x(4) ...
if(nargin<2)
    Lines=[(1:(size(Vertices,1)-1))' (2:size(Vertices,1))'];
end
% disp(size(Lines))
% Get left and right neighbor of each points
Na=zeros(size(Vertices,1),1); Nb=zeros(size(Vertices,1),1);
Na(Lines(:,1))=Lines(:,2); Nb(Lines(:,2))=Lines(:,1);

% Check for end of line points, without a left or right neighbor
checkNa=Na==0; checkNb=Nb==0;
Naa=Na; Nbb=Nb;
Naa(checkNa)=find(checkNa); Nbb(checkNb)=find(checkNb);

% If no left neighbor use two right neighbors, and the same for right... 
Na(checkNa)=Nbb(Nbb(checkNa)); Nb(checkNb)=Naa(Naa(checkNb));

% Correct for sampeling differences
Ta=-sqrt(sum((Vertices-Vertices(Na,:)).^2,2));
Tb=sqrt(sum((Vertices-Vertices(Nb,:)).^2,2)); 

% If no left neighbor use two right neighbors, and the same for right... 
Ta(checkNa)=-Ta(checkNa); Tb(checkNb)=-Tb(checkNb);

% Fit a polygons to the vertices 
% x=a(3)*t^2 + a(2)*t + a(1) 
% y=b(3)*t^2 + b(2)*t + b(1) 
% we know the x,y of every vertice and set t=0 for the vertices, and
% t=Ta for left vertices, and t=Tb for right vertices,  
x = [Vertices(Na,1) Vertices(:,1) Vertices(Nb,1)];
y = [Vertices(Na,2) Vertices(:,2) Vertices(Nb,2)];
M = [ones(size(Tb)) -Ta Ta.^2 ones(size(Tb)) zeros(size(Tb)) zeros(size(Tb)) ones(size(Tb)) -Tb Tb.^2];
invM=inverse3(M);
a(:,1)=invM(:,1,1).*x(:,1)+invM(:,2,1).*x(:,2)+invM(:,3,1).*x(:,3);
a(:,2)=invM(:,1,2).*x(:,1)+invM(:,2,2).*x(:,2)+invM(:,3,2).*x(:,3);
a(:,3)=invM(:,1,3).*x(:,1)+invM(:,2,3).*x(:,2)+invM(:,3,3).*x(:,3);
b(:,1)=invM(:,1,1).*y(:,1)+invM(:,2,1).*y(:,2)+invM(:,3,1).*y(:,3);
b(:,2)=invM(:,1,2).*y(:,1)+invM(:,2,2).*y(:,2)+invM(:,3,2).*y(:,3);
b(:,3)=invM(:,1,3).*y(:,1)+invM(:,2,3).*y(:,2)+invM(:,3,3).*y(:,3);

% Calculate the curvature from the fitted polygon
k = 2*(a(:,2).*b(:,3)-a(:,3).*b(:,2)) ./ ((a(:,2).^2+b(:,2).^2).^(3/2));
end

function  Minv  = inverse3(M)
% This function does inv(M) , but then for an array of 3x3 matrices
adjM(:,1,1)=  M(:,5).*M(:,9)-M(:,8).*M(:,6);
adjM(:,1,2)=  -(M(:,4).*M(:,9)-M(:,7).*M(:,6));
adjM(:,1,3)=  M(:,4).*M(:,8)-M(:,7).*M(:,5);
adjM(:,2,1)=  -(M(:,2).*M(:,9)-M(:,8).*M(:,3));
adjM(:,2,2)=  M(:,1).*M(:,9)-M(:,7).*M(:,3);
adjM(:,2,3)=  -(M(:,1).*M(:,8)-M(:,7).*M(:,2));
adjM(:,3,1)=  M(:,2).*M(:,6)-M(:,5).*M(:,3);
adjM(:,3,2)=  -(M(:,1).*M(:,6)-M(:,4).*M(:,3));
adjM(:,3,3)=  M(:,1).*M(:,5)-M(:,4).*M(:,2);
detM=M(:,1).*M(:,5).*M(:,9)-M(:,1).*M(:,8).*M(:,6)-M(:,4).*M(:,2).*M(:,9)+M(:,4).*M(:,8).*M(:,3)+M(:,7).*M(:,2).*M(:,6)-M(:,7).*M(:,5).*M(:,3);
Minv=bsxfun(@rdivide,adjM,detM);
end


