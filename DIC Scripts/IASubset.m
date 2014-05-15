function IA = IASubset(image,width,x_loc,y_loc)
if x_loc < width/2 || y_loc < width/2
    fprintf('Subset error: please choose a location at least %d pixels away from the edge',width/2)
else
    IA = image(y_loc-width/2+1:y_loc+width/2,x_loc-width/2+1:x_loc+width/2);
%     window = ones(width);
%     [x,y] = meshgrid(0:width-1,0:width-1);
%     x_win = sin(x*pi/(width-1))^2;
%     y_win = sin(y*pi/(width-1))^2;
%     window = window.*x_win.*y_win;
%     window = window/max(max(window));
%     IA = IA.*window;
end
    
    