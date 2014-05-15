%This is a sample DIC script. Free feel to modify it however you like.
%image1 and image2 are the two images to correlate. Make sure to import
%them using the imread() function. image1 is the undeformed image and image 2
%is the deformed image. xtrans and ytrans are the x and y translations.
image1 = imread('Water.jpg');
image2 = imread('Example.jpg');
ImgA = im2double(image1);
ImgB = im2double(image2);
[n,m] = size(ImgA);

%DIC works by correlating X-by-X pixel regions. X should be at least twice
%as much as the number of pixels you expect for translation to occur. E.g.,
%if you expect maximum translation to occur over 10 pixels then X should be
%20. Take note that bigger X requires longer runtimes.
max_trans = 20;
width = 40;


%To speed things up, we will only correlate region of interests.'
figure(1)

check = 'N';
while check == 'N';
    clf
    hold on
imagesc(ImgB);
fprintf('\n Please click on the lower left of the region of interest, \n then click on the upper right');
ROI = ginput(2);
q = fill(ROI([1 2 2 1],1),ROI([1 1 2 2] ,2),'y');
set(q,'facealpha',0.5);
shg
check = input('\n Is this the region of interest you want? (Y/N) \n','s');
end

xlength = floor(abs(ROI(1,1) - ROI(2,1)));
ylength = floor(abs(ROI(1,2) - ROI(2,2)));

%Pick the step_size(resolution) of your DIC output. Step_size = 1 is the
%same resolution as the input image. Step_size = 5 is 1/5 the resolution.
step_size = 5;

ysteps = length(width/2:step_size:ylength-width/2);
xsteps = length(width/2:step_size:xlength-width/2);
xtrans1 = (zeros(ysteps,xsteps));
ytrans1 = (zeros(ysteps,xsteps));

% Run through each interrogation region and find image displacement.  Map
% into x and y translation matricies.
for i = 0:ysteps-1
    for j = 0:xsteps-1
        % Current x,y location
        y_loc = i*step_size+width/2+floor(ROI(1,2));
        x_loc = j*step_size+width/2+floor(ROI(1,1));
        
        % Create DIC subset from ImgB
        IA_B = IASubset(ImgB,width,x_loc,y_loc);
        a = floor(y_loc-width/2+1-max_trans:y_loc+width/2+max_trans);
        b = floor(x_loc-width/2+1-max_trans:x_loc+width/2+max_trans);
        % Create subset of image A (larger by 2*max_trans)
        ImSubset = ImgA(a,b);
        % if inside the triangle, don't try to correlate.
        if mean(mean(IA_B)) < 0.01
            ytrans1(i+1,j+1)= 0;
            xtrans1(i+1,j+1)= 0;
        else

            % Correlate images
            RAB = normxcorr2(IA_B,ImSubset);
    %         RAB = gather(RAB);
            [~, imax] = max(abs(RAB(:)));
            [ypeak, xpeak] = ind2sub(size(RAB),imax(1));

            %%%%% comment below to disable wathcing th correlation:
    %         figure(1);
    %         subplot(1,2,1)
    %         imshow(ImSubset)
    %         subplot(1,2,2)
    %         imshow(RAB)

            % Sub Pixel Correlating:

            [RAB_n,RAB_m] = size(RAB);
            if xpeak <= 1 || xpeak >= RAB_m
                xpeak_new = xpeak;
            else
                xpeak_new = xpeak+(RAB(ypeak,xpeak-1)-RAB(ypeak,xpeak+1))/(2*RAB(ypeak,xpeak-1)-4*RAB(ypeak,xpeak)+2*RAB(ypeak,xpeak+1))-max_trans-width;
            end
            if ypeak <= 1 || ypeak >= RAB_n
                ypeak_new = ypeak;
            else
            ypeak_new = ypeak+(RAB(ypeak-1,xpeak)-RAB(ypeak+1,xpeak))/(2*RAB(ypeak-1,xpeak)-4*RAB(ypeak,xpeak)+2*RAB(ypeak+1,xpeak))-max_trans-width;
            end


            % Through translations into matricies
            ytrans1(i+1,j+1)= ypeak_new;
            xtrans1(i+1,j+1)= xpeak_new;
        end
    end
end
%Get rid of outliers:
% xtrans1 = gather(xtrans1);
% ytrans1 = gather(ytrans1);
% xtrans = (xtrans1);
% ytrans = (ytrans1);
truthy = abs(ytrans1) < 25.*ones(size(ytrans1));
ytrans = truthy.*ytrans1;
truthy = abs(xtrans1) <30.*ones(size(xtrans1));
xtrans = truthy.*xtrans1;

%pixels per meter:
ppm = 175600;

% Create real world coordinates
x_pix = width/2:step_size:xlength-width/2;
y_pix = width/2:step_size:ylength-width/2;
x = x_pix./ppm;
y = fliplr(y_pix./ppm);
% xtrans_norm = (xtrans-min(min(abs(xtrans1))))/ppm;
% ytrans_norm = (ytrans-min(min(abs(ytrans1))))/ppm;
xtrans_norm = (xtrans)/ppm;
ytrans_norm = ytrans/ppm;
mag_norm = sqrt(xtrans_norm.^2+ytrans_norm.^2);
% truthy = ytrans_norm>0;
% ytrans_norm = ytrans_norm.*truthy;
% Plot x and y translation
figure(2)
imagesc(x,y,xtrans_norm)
axis xy
axis image
title('X Translation between Images','fontsize',12);
xlabel('Horizontal Position (m)','fontsize',12)
ylabel('Vertical Position (m)','fontsize',12)
colorbar
colormap jet
figure(3)
imagesc(x,y,ytrans_norm)
axis xy
axis image
title('Y Translation between Images','fontsize',12);
xlabel('Horizontal Position (m)','fontsize',12)
ylabel('Vertical Position (m)','fontsize',12)
colorbar
colormap jet
figure(4)
imagesc(x,y,mag_norm)
axis xy
axis image
title('Translation magnitude between Images','fontsize',12);
xlabel('Horizontal Position (m)','fontsize',12)
ylabel('Vertical Position (m)','fontsize',12)
colorbar
colormap jet

%Poisson Ratio
poisson_rat = (max(max(abs(xtrans_norm)))-min(min(abs(xtrans_norm))))/(max(max(ytrans_norm))-min(min(ytrans_norm)));
% Strain calculations deltaL/L_tot
xtrans_norm = (xtrans-min(min(abs(xtrans1))))/ppm;
ytrans_norm = (ytrans-min(min(abs(ytrans1))))/ppm;

% IA = ImgB(ypeak-width+1:ypeak,xpeak-width+1:xpeak);
% imshowpair(IA,IA_A)