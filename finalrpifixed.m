%Initialize raspberry pi zero W and camera settings
%rpi= raspi();
%mycam = cameraboard(rpi,'Resolution','1920x1080');
%mycam.Brightness = 70;
%Define GPIO pins
pin1=configurePin(rpi,14,'DigitalOutput');
pin2=configurePin(rpi,22,'DigitalOutput');
pin3=configurePin(rpi,23,'DigitalOutput');
pin4=configurePin(rpi,24,'DigitalOutput');
pin5=configurePin(rpi,5,'DigitalOutput');
pin6=configurePin(rpi,12,'DigitalOutput');
pin7=configurePin(rpi,16,'DigitalOutput');
pin8=configurePin(rpi,25,'DigitalOutput');
pin9=configurePin(rpi,19,'DigitalOutput');
pin10=configurePin(rpi,20,'DigitalOutput');
%create an array of GPIO pins
RpiPins= [14,22,23,24,5,12,16,25,19,20];
%Initialize pin values
pinstates = [1,1,1,1,1,1,1,1,1,1];
%Initialize main image for position reference
imgMain = snapshot(mycam);
%imshow(imgMain);
%imdistline;
imgMainGray = rgb2gray(img);
[centersMain, radiiMain] = imfindcircles(imgMainGray, [40, 80], 'ObjectPolarity', 'bright');
centersCopy = centersMain;
centersCopySorted = sortrows(centersCopy, 2);
sortedByRow = discretize(centersCopySorted(:,2),4);
centersCopySorted = [centersCopySorted, sortedByRow];
sortedTotal = splitapply(@(centersCopySorted){sort(centersCopySorted, 1)}, centersCopySorted, sortedByRow);
centersMainPos = cat(1, cell2mat(sortedTotal(1)), cell2mat(sortedTotal(2)), cell2mat(sortedTotal(3)), cell2mat(sortedTotal(4)));
while 1
    pause(2); % Wait 5 seconds until a new shot is taken to save computation load
    % Get image after throw
    img = snapshot(mycam);
    pause(1);
    img = snapshot(mycam);
    pause(1);
    img = snapshot(mycam);
    pause(2);
    
    imgGray = rgb2gray(img);
    
    standingList = [];
    threshold = 110;
    for i = 1:length(centersMainPos)
        % Get pixel values for the center point of the pin
        pin = impixel(imgGray, centersMainPos(i, 1), centersMainPos(i, 2));
        rcheck = pin(1) > threshold;
        gcheck = pin(2) > threshold;
        bcheck = pin(3) > threshold;
        standing = rcheck & gcheck & bcheck;
        if standing
            standingList = [standingList, i];
        end
    end
    
    for i = 1:length(centersMainPos)
        if ismember(i, standingList)
            % PINSTATE HIGH
            pinstates(i) = 1;
            writeDigitalPin(rpi,RpiPins(i),1);
        else
            % PINSTATE LOW
            pinstates(i) = 0;
            writeDigitalPin(rpi,RpiPins(i),0);
        end
    end
    
end
clear('mycam');
