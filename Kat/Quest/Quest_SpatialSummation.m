%Code to run a QUEST/ZEST threshold experiment (Spatial Summation); W. Tuten 6-22-2010

%first, decide on shape with which to test spatial summation

bmpimage = zeros(512,512);
[x,y] = size(bmpimage);

xcenter = x/2;
ycenter = x/2;

button = questdlg('Which shape would you like to use?','Select .bmp Shape','Square','Circle','Rectangle','Square');
switch button,
    case 'Square'
        prompt = {'Enter square width:'};
        dlg_title = 'Input stimulus size...';
        num_lines = 1;
        def = {'20'};
        width = inputdlg(prompt,dlg_title,num_lines,def);
        halfwidth = str2num(width{1})/2;
        bmpimage(ycenter-halfwidth:ycenter+halfwidth, xcenter-halfwidth:xcenter+halfwidth) =1;
        figure, imshow(bmpimage), axis square
        imwrite(bmpimage,'MP_bmpfile.bmp','bmp');
        tGuess = 3; %square width
        
        if exist('GetSecs')
            getSecsFunction='GetSecs';
        else
            getSecsFunction='cputime';
        end

        % Provide our prior knowledge to QuestCreate, and receive the data struct "q".
        % tGuess=input('Estimate threshold (e.g. -1): ');
        % background = 0.0; spotguess = 0.05; MichCont = abs((background-spotguess)/(background+spotguess));
        %tGuess = 2;
        % tGuessSd=input('Estimate the standard deviation of your guess, above, (e.g. 2): ');
        tGuessSd = 3.0;
        pThreshold=0.82;
        beta=3.5;delta=0.01;gamma=0.5;
        q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma);
        q.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.

        wrongRight={'wrong','right'};
        timeZero=eval(getSecsFunction);

        trialsDesired = 30;


        for k=1:trialsDesired
            bmpimage = zeros(512,512);
            % Get recommended level.  Choose your favorite algorithm.
        %	tTest=QuestQuantile(q);	% Recommended by Pelli (1987), and still our favorite.
            tTest=QuestMean(q);		% Recommended by King-Smith et al. (1994)
        % 	tTest=QuestMode(q);		% Recommended by Watson & Pelli (1983)
	
            % We are free to test any intensity we like, not necessarily what Quest suggested.
        % 	tTest=min(-0.05,max(-3,tTest)); % Restrict to range of log contrasts that our equipment can produce.
	
            % Simulate a trial
            timeSplit=eval(getSecsFunction); % Omit simulation and printing from the timing measurements.
            %response=QuestSimulate(q,tTest,tActual);
            suggested_width = tTest; halfwidth = suggested_width/2;
            bmpimage(ycenter-halfwidth:ycenter+halfwidth, xcenter-halfwidth:xcenter+halfwidth) =1;
            imshow(bmpimage), axis square
            %imshow(bmpnew),axis square, hold on
            response = input('Do you see the square? Y = 1; N = 0: ');
            %fprintf('Trial %3d at %4.1f is %s\n',k,tTest,char(wrongRight(response+1)));
            timeZero=timeZero+eval(getSecsFunction)-timeSplit;
	
            % Update the pdf
            q=QuestUpdate(q,tTest,response); % Add the new datum (actual test intensity and observer response) to the database.
        end

        % Print results of timing.
        fprintf('%.0f ms/trial\n',1000*(eval(getSecsFunction)-timeZero)/trialsDesired);

        % Ask Quest for the final estimate of threshold.
        t=QuestMean(q);		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
        sd=QuestSd(q);
        fprintf('Final threshold estimate (mean ± sd) is %.2f ± %.2f\n',t,sd);
%%-------------------------------------------------------------------------
%%-------------------------------------------------------------------------
    case 'Circle'
        prompt = {'Enter circle radius:'};
        dlg_title = 'Input stimulus size...'; 
        num_lines =1;
        def = {'100'};
        circradius = inputdlg(prompt,dlg_title,num_lines,def);
        r = str2num(circradius{1});
        for radius = 1:r
            theta = [0:0.001:2*pi];
            xcircle = radius*cos(theta)+ xcenter; ycircle = radius*sin(theta)+ ycenter;
            xcircle = round(xcircle); ycircle = round(ycircle);
            n = size(xcircle); n = n(2);
            xymat = [xcircle' ycircle'];
            for point = 1:n
                row = xymat(point,2); col = xymat(point,1); 
                bmpimage(row,col)= 1;
            end
        end
        bmpimage(ycenter,xcenter)=1;
        figure, imshow(bmpimage), axis square
        imwrite(bmpimage,'MP_bmpfile.bmp','bmp');
        
        tGuess = 1.5*1.5*3.1415; %circle area
        
        if exist('GetSecs')
            getSecsFunction='GetSecs';
        else
            getSecsFunction='cputime';
        end

        % Provide our prior knowledge to QuestCreate, and receive the data struct "q".
        % tGuess=input('Estimate threshold (e.g. -1): ');
        % background = 0.0; spotguess = 0.05; MichCont = abs((background-spotguess)/(background+spotguess));
        %tGuess = 2;
        % tGuessSd=input('Estimate the standard deviation of your guess, above, (e.g. 2): ');
        tGuessSd = 9.0;
        pThreshold=0.82;
        beta=3.5;delta=0.01;gamma=0.5;
        q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma);
        q.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.

        wrongRight={'wrong','right'};
        timeZero=eval(getSecsFunction);

        trialsDesired = 30;


        for k=1:trialsDesired
            bmpimage = zeros(512,512);
            % Get recommended level.  Choose your favorite algorithm.
        %	tTest=QuestQuantile(q);	% Recommended by Pelli (1987), and still our favorite.
            tTest=QuestMean(q);		% Recommended by King-Smith et al. (1994)
        % 	tTest=QuestMode(q);		% Recommended by Watson & Pelli (1983)
	
            % We are free to test any intensity we like, not necessarily what Quest suggested.
        % 	tTest=min(-0.05,max(-3,tTest)); % Restrict to range of log contrasts that our equipment can produce.
	
            % Simulate a trial
            timeSplit=eval(getSecsFunction); % Omit simulation and printing from the timing measurements.
            %response=QuestSimulate(q,tTest,tActual);
            r = tTest;
            for radius = 1:r
            theta = [0:0.001:2*pi];
            xcircle = radius*cos(theta)+ xcenter; ycircle = radius*sin(theta)+ ycenter;
            xcircle = round(xcircle); ycircle = round(ycircle);
            n = size(xcircle); n = n(2);
            xymat = [xcircle' ycircle'];
                for point = 1:n
                    row = xymat(point,2); col = xymat(point,1); 
                    bmpimage(row,col)= 1;
                end
            end
            bmpimage(ycenter,xcenter)=1;
            imshow(bmpimage), axis square
            %imshow(bmpnew),axis square, hold on
            response = input('Do you see the circle? Y = 1; N = 0: ');
            %fprintf('Trial %3d at %4.1f is %s\n',k,tTest,char(wrongRight(response+1)));
            timeZero=timeZero+eval(getSecsFunction)-timeSplit;
	
            % Update the pdf
            q=QuestUpdate(q,tTest,response); % Add the new datum (actual test intensity and observer response) to the database.
        end

        % Print results of timing.
        fprintf('%.0f ms/trial\n',1000*(eval(getSecsFunction)-timeZero)/trialsDesired);
        
        % Ask Quest for the final estimate of threshold.
        t=QuestMean(q);		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
        sd=QuestSd(q);
        fprintf('Final threshold estimate (mean ± sd) is %.2f ± %.2f\n',t,sd);
        
%%-------------------------------------------------------------------------
%%-------------------------------------------------------------------------
      
    case 'Rectangle'
        prompt = {'Enter rectangle width:', 'Enter rectangle height:'};
        dlg_title = 'Input stimulus size...';
        num_lines = 1;
        def = {'2', '20'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        halfwidth = str2num(answer{1})/2;
        halfheight = str2num(answer{2})/2;
        bmpimage(ycenter-halfheight:ycenter+halfheight, xcenter-halfwidth:xcenter+halfwidth) =1;
        figure, imshow(bmpimage), axis square
        imwrite(bmpimage,'MP_bmpfile.bmp','bmp');  
        
        tGuess = 1.5; %rectangle width
        
        if exist('GetSecs')
            getSecsFunction='GetSecs';
        else
            getSecsFunction='cputime';
        end

        % Provide our prior knowledge to QuestCreate, and receive the data struct "q".
        % tGuess=input('Estimate threshold (e.g. -1): ');
        % background = 0.0; spotguess = 0.05; MichCont = abs((background-spotguess)/(background+spotguess));
        %tGuess = 2;
        % tGuessSd=input('Estimate the standard deviation of your guess, above, (e.g. 2): ');
        tGuessSd = 3.0;
        pThreshold=0.82;
        beta=3.5;delta=0.01;gamma=0.5;
        q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma);
        q.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.

        wrongRight={'wrong','right'};
        timeZero=eval(getSecsFunction);

        trialsDesired = 30;


        for k=1:trialsDesired
            bmpimage = zeros(512,512);
            % Get recommended level.  Choose your favorite algorithm.
        %	tTest=QuestQuantile(q);	% Recommended by Pelli (1987), and still our favorite.
            tTest=QuestMean(q);		% Recommended by King-Smith et al. (1994)
        % 	tTest=QuestMode(q);		% Recommended by Watson & Pelli (1983)
	
            % We are free to test any intensity we like, not necessarily what Quest suggested.
        % 	tTest=min(-0.05,max(-3,tTest)); % Restrict to range of log contrasts that our equipment can produce.
	
            % Simulate a trial
            timeSplit=eval(getSecsFunction); % Omit simulation and printing from the timing measurements.
            %response=QuestSimulate(q,tTest,tActual);
            suggested_height = tTest; halfheight = suggested_height/2;
            %bmpimage(ycenter-halfwidth:ycenter+halfwidth, xcenter-halfwidth:xcenter+halfwidth) =1;
            bmpimage(ycenter-halfheight:ycenter+halfheight, xcenter-halfwidth:xcenter+halfwidth) =1;
            imshow(bmpimage), axis square
            %imshow(bmpnew),axis square, hold on
            response = input('Do you see the square? Y = 1; N = 0: ');
            %fprintf('Trial %3d at %4.1f is %s\n',k,tTest,char(wrongRight(response+1)));
            timeZero=timeZero+eval(getSecsFunction)-timeSplit;
	
            % Update the pdf
            q=QuestUpdate(q,tTest,response); % Add the new datum (actual test intensity and observer response) to the database.
        end

        % Print results of timing.
        fprintf('%.0f ms/trial\n',1000*(eval(getSecsFunction)-timeZero)/trialsDesired);

        % Ask Quest for the final estimate of threshold.
        t=QuestMean(q);		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
        sd=QuestSd(q);
        fprintf('Final threshold estimate (mean ± sd) is %.2f ± %.2f\n',t,sd);
        
end

% GetSecs is part of the Psychophysics Toolbox.  If you are running 
% QuestDemo without the Psychtoolbox, we use CPUTIME instead of GetSecs.
close all, clear all

