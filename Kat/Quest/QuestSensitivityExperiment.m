function RunQuestSensitivityExperiment

global serialPort mode StimParams
%global StimParams

if exist('handles') == 0;
    handles = guihandles;
else
    %donothing
end

%get experiment config data stored in appdata for 'hAomControl'
hAomControl = getappdata(0,'hAomControl');
CFG = getappdata(hAomControl, 'CFG');


%setup the keyboard constants and response mappings from config
kb_AbortConst = 27; %abort constant - Esc Key

%kb_LeftConst = 28; %ascii code for left arrow
%kb_RightConst = 29; %ascii code for right arrow
kb_YesConst = 30; %ascii code for up arrow
kb_NoConst = 31; %ascii code for down arrow

kb_StimConst = CFG.kb_StimConst;
kb_UpArrow = CFG.kb_UpArrow;
kb_DownArrow = CFG.kb_DownArrow;
kb_LeftArrow = CFG.kb_LeftArrow;
kb_RightArrow = CFG.kb_RightArrow;

%disable slider control during exp
set(handles.align_slider, 'Enable', 'off');
if StimParams.aom == 0;
    set(handles.aom0_state, 'String', 'Starting Experiment...');
else
    set(handles.aom1_state, 'String', 'Starting Experiment...');
end

%set up QUEST params
maxQuestCon = 5;

thresholdGuess = CFG.thresholdGuess;
priorSD = CFG.priorSD;
pCorrect = CFG.pCorrect/100;
nIntervals = CFG.nIntervals;
beta = CFG.beta;
delta = CFG.delta;
gamma=.25;
fps = 30;
presentdur = CFG.presentdur/1000;
stimdur = fps*presentdur;
iti = CFG.iti/1000;
ntrials = CFG.npresent;
nresponses = CFG.responses;

%get the stimulus parameters
dirname = StimParams.dirname;
fprefix = StimParams.fprefix;
findices = StimParams.findices;
mapfname = StimParams.mapfname;
fieldsize = CFG.fieldsize;

fid = fopen([dirname mapfname]);
mapping = fscanf(fid, '%f%f',[2,inf])';
fclose(fid);
stim = unique(mapping(:,2)).*fieldsize;
stepsize = stim(end)-stim(end-1);

%set up the movie parameters
Mov.dir = dirname;
Mov.suppress = 0;
Mov.pfx = fprefix;

aom = StimParams.aom;
Mov.aom = aom;
%initialize QUEST
q=QuestCreate(thresholdGuess,priorSD,pCorrect,beta,delta,gamma);
 
%generate a psyfile
psyfname = GenPsyFileName;

%write header to file
GenerateHeader(psyfname);

%set initial while loop conditions
runExperiment = 1;
trial = 1;
PresentStimulus = 1;
GetResponse = 0;
if aom == 0;
    set(handles.aom0_onoff, 'Value', 1);
    aom0_onoff_Callback;
elseif aom == 1;
    set(handles.aom1_onoff, 'Value', 1);
    aom1_onoff_Callback;
end
set(handles.aom_main_figure, 'KeyPressFcn','uiresume');

while(runExperiment ==1)
    uiwait;
    resp = get(handles.aom_main_figure,'CurrentCharacter');

    if(resp == kb_AbortConst);

        runExperiment = 0;
        uiresume;
        expdone;
        message = ['Off - Experiment Aborted - Trial ' num2str(trial) ' of ' num2str(ntrials)];

        if StimParams.aom == 0;
            set(handles.aom0_state, 'String',message);
        elseif StimParams.aom == 1;
            set(handles.aom1_state, 'String',message);
        end

        if CFG.filter(1) ~= 'n'
            rmdir([pwd,'\temp'],'s');
        else
        end

    elseif(resp == kb_StimConst)    % check if present stimulus button was pressed

%                 initialize_SerialPort;
%                 command = ['GRVID#' sprintf('%10d',1) '#'];
%                  MATLABAomControl32(command);
%                 fprintf(serialPort,command);   % send command over serial port to imaging software
%                 fclose(serialPort);

        if PresentStimulus == 1;
            %find out the new lettersize for this trial (from QUEST)
            questSize=QuestQuantile(q);

            %This makes the next trial size equal to the next smallest
            %size letter
            if questSize > stim(end)
                trialSize = stim(end);
            elseif questSize < stim(end) && questSize > stim(end-1)
                trialSize = stim(end-1);
            elseif questSize < stim(end-1) && questSize > stim(end-2)
                trialSize = stim(end-2);
            elseif questSize < stim(end-2) && questSize > stim(end-3);
                trialSize = stim(end-3);
            elseif questSize < stim(end-3) && questSize > stim(end-4);
                trialSize = stim(end-4);
            elseif questSize < stim(end-4) && questSize > stim(end-5);
                trialSize = stim(end-5);
            elseif questSize < stim(end-5) && questSize > stim(end-6);
                trialSize = stim(end-6);
            elseif questSize < stim(end-6) && questSize > stim(end-7);
                trialSize = stim(end-7);
            elseif questSize < stim(end-7) && questSize > stim(end-8);
                trialSize = stim(end-8);
            elseif questSize < stim(end-8) && questSize > stim(end-9)
                trialSize = stim(end-9);
            elseif questSize < stim(end-9) && questSize > stim(end-10)
                trialSize = stim(end-10);
            elseif questSize < stim(end-10) && questSize > stim(end-11);
                trialSize = stim(end-11);
            elseif questSize < stim(end-11) && questSize > stim(end-12);
                trialSize = stim(end-12);
            elseif questSize < stim(end-12) && questSize > stim(end-13);
                trialSize = stim(end-13);
            elseif questSize < stim(end-13) && questSize > stim(end-14);
                trialSize = stim(end-14);
            elseif questSize < stim(end-14) && questSize > stim(end-15);
                trialSize = stim(end-15);
            elseif questSize < stim(end-15);
                trialSize = stim(end-15);
            else
            end

            stimulus = find(mapping(:,3).*fieldsize == trialSize);


            whichstim = round(rand.*(nresponses-1))+1;

            stimulus = stimulus(whichstim);

            framenum = mapping(stimulus,1);%% have to add one here b/c frames start at 2 now

            seq = [ones(1,stimdur).*framenum 1];

            %set up the movie params
            Mov.frm = 1;
            Mov.sfr = 1;
            Mov.seq = seq;
            Mov.efr = 0;
            Mov.lng = stimdur+1;
            message = ['Running Experiment - Trial ' num2str(trial) ' of ' num2str(ntrials)];
            Mov.msg = message;
            setappdata(hAomControl, 'Mov',Mov);

            PlayMovie;

            PresentStimulus = 0;
            GetResponse = 1;
        end

    elseif(GetResponse == 1)
        if(resp == kb_YesConst)
            response = kb_UpArrow;
        elseif(resp == kb_NoConst)
            response = kb_DownArrow;
%         elseif(resp == kb_LeftConst)
%             response = kb_LeftArrow;
%         elseif(resp == kb_RightConst)
%             response = kb_RightArrow;
        else
            response = 'N';
        end;

        %see if response is correct and display (or provide feedback)

        if(response ~= 'N')
            if response == mapping(stimulus,2)
                message1 = [Mov.msg ' - ' response ' - Correct'];
                message2 = ['QUEST Threshold Estimate (Diameter in minutes): ' num2str(QuestMean(q),3)];
                message = sprintf('%s\n%s', message1, message2);
                if StimParams.aom == 0;
                    set(handles.aom0_state, 'String',message);
                elseif StimParams.aom == 1;
                    set(handles.aom1_state, 'String',message);
                end
                mar = mapping(stimulus,3);
                correct = 1;
            else
                message1 = [Mov.msg ' - ' response ' - Incorrect'];
                message2 = ['QUEST Threshold Estimate (Diameter in minutes): ' num2str(QuestMean(q),3)];
                message = sprintf('%s\n%s', message1, message2);
                if StimParams.aom == 0;
                    set(handles.aom0_state, 'String',message);
                elseif StimParams.aom == 1;
                    set(handles.aom1_state, 'String',message);
                end
                mar = mapping(stimulus,3);
                correct = 0;
            end



            %write response to psyfile
            psyfid = fopen(psyfname,'a');
            fprintf(psyfid,'%2.0f\t%s\t%4.4f\t%4.4f\t%4.4f\t%4.4f\t%1.0f\n',framenum,response,questSize,mar,QuestMean(q),QuestSd(q),correct);
            fclose(psyfid);
            theThreshold(trial,1) = QuestMean(q);

            %update QUEST
            q = QuestUpdate(q,trialSize,correct);

            %update trial counter
            trial = trial + 1;

            if(trial > ntrials)
                runExperiment = 0;


                set(handles.aom_main_figure, 'keypressfcn','');
                expdone;
                message = ['Off - Experiment Complete - MAR: ' num2str(QuestMean(q),3) ' ± ' num2str(QuestSd(q),3)];

                if aom == 0
                    set(handles.aom0_state, 'String',message);
                elseif aom == 1
                    set(handles.aom1_state, 'String',message);
                end
                figure;
                plot(theThreshold);
                xlabel('Trial number');
                ylabel('MAR (Arc Minutes)');
                title('Threshold estimate vs. Trial Number');
                if CFG.filter(1) ~= 'n'
                    rmdir([pwd,'\temp'],'s');
                else
                end

            else %continue experiment
            end
            GetResponse = 0;
            PresentStimulus = 1;

        end
    end
end
