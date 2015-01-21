function SimpleExposure_Training(varargin)

global KEY COLORS w wRect XCENTER YCENTER PICS STIM SimpExp trial pahandle

%This is for food exposure!

prompt={'SUBJECT ID' 'Condition' 'fMRI'};
defAns={'4444' '1' '0'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
COND = str2double(answer{2});
fmri = str2double(answer{3});
% SESS = str2double(answer{3});
% prac = str2double(answer{4});


rng(ID); %Seed random number generator with subject ID
d = clock;

KEY = struct;
KEY.rt = KbName('SPACE');
KEY.left = KbName('c');
KEY.right = KbName('m');
KEY.trigger = KbName('''"');


COLORS = struct;
COLORS.BLACK = [0 0 0];
COLORS.WHITE = [255 255 255];
COLORS.RED = [255 0 0];
COLORS.BLUE = [0 0 255];
COLORS.GREEN = [0 255 0];
COLORS.YELLOW = [255 255 0];
COLORS.rect = COLORS.GREEN;

STIM = struct;
STIM.blocks = 6;
STIM.trials = 10;
STIM.totes = STIM.blocks*STIM.trials;
STIM.trialdur = 5;
STIM.jitter = [2 3 4];


%% Keyboard stuff for fMRI...

%list devices
[keyboardIndices, productNames] = GetKeyboardIndices;

isxkeys=strcmp(productNames,'Xkeys');

xkeys=keyboardIndices(isxkeys);
macbook = keyboardIndices(strcmp(productNames,'Apple Internal Keyboard / Trackpad'));

%in case something goes wrong or the keyboard name isn?t exactly right
if isempty(macbook)
    macbook=-1;
end

%in case you?re not hooked up to the scanner, then just work off the keyboard
if isempty(xkeys)
    xkeys=macbook;
end

%% Find & load in pics
%find the image directory by figuring out where the .m is kept
[mdir,~,~] = fileparts(which('SimpleExposure_Training.m'));

% [ratedir,~,~] = fileparts(which('PicRatings_U4ED.m'));
picratefolder = fullfile(mdir,'Ratings');   %xXX: Double check this is right folder!!!
% imgdir = fullfile(ratedir,'Pics');
imgdir = '/Users/canelab/Documents/StudyTasks/MasterPics';

try
    cd(picratefolder)
catch
    error('Could not find and/or open the folder that contains the image ratings.');
end


if COND ==1;    %If EXP condition!
    filen = sprintf('PicRate_Training_%d.mat',ID);
    try
        p = open(filen);
    catch
        warning('Attemped to open file called "%s" for Subject #%d. Could not find and/or open this training rating file. Double check that you have typed in the subject number appropriately.',filen,ID);
        commandwindow;
        randopics = input('Would you like to continue with a random selection of images? [1 = Yes, 0 = No]');
        if randopics == 1
            cd(imgdir)
            p = struct;
            p.PicRating.no = dir('Unhealthy*');
            p.PicRating.go = dir('Healthy*');
            
        else
            error('Task cannot proceed without images. Contact Erik (elk@uoregon.edu) if you have continued problems.')
        end
        
    end
    PICS.in.hi = struct('name',{p.PicRating.no(1:100).name}');
    PICS.in.lo = struct('name',{p.PicRating.go(1:100).name}');
else
    cd(imgdir)
    p = struct;
    PICS.in.hi = dir('Unhealthy*');
    PICS.in.lo = dir('Healthy*');
end

    

cd(imgdir);

neutpics = dir('water*');

%Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(neutpics) || isempty(PICS.in.hi) %|| isempty(neutpics)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end

%% Fill in rest of pertinent info
SimpExp = struct;


    %1 = hi cal food, 2 = low cal food, 0 = water
    pictype = [ones(40,1); repmat(2,40,1); zeros(20,1)];

if COND == 1    
    %1 = in training tasks, 0 = not in training tasks
    trainpic = [repmat([ones(20,1); zeros(20,1)],2,1); zeros(20,1)];
    
    %Make long list of randomized #s to represent each pic
    %Need random 20 from top 80 pics + random ordering of next 20 pics
    %Repeat for low cal food...
    piclist = [randperm(80,20)'; (randperm(20)+80)'; randperm(80,20)'; (randperm(20)+80)'; randperm(length(neutpics),20)'];
    
else
    %Otherwise, all pics are NOT in training tasks and are thus randomly
    %selected from entire list of possible pics.
    
    trainpic = zeros(length(pictype),1);
    piclist = [randperm(length(PICS.in.hi),40)'; randperm(length(PICS.in.lo),40)'; randperm(length(neutpics),20)'];
end

%Concatenate these into a long list of trial types.
trial_types = [pictype trainpic piclist];
shuffled = trial_types(randperm(size(trial_types,1)),:);

jitter = BalanceTrials(STIM.totes,1,STIM.jitter);

 for x = 1:STIM.blocks
     for y = 1:STIM.trials;
         tc = (x-1)*STIM.trials + y;
         SimpExp.data(tc).pictype = shuffled(tc,1);
         SimpExp.data(tc).training = shuffled(tc,2);
         if shuffled(tc,1) == 1
            SimpExp.data(tc).picname = PICS.in.hi(shuffled(tc,3)).name;
         elseif shuffled(tc,1) == 0
             SimpExp.data(tc).picname = neutpics(shuffled(tc,3)).name;
         elseif shuffled(tc,1) == 2;
             SimpExp.data(tc).picname = PICS.in.lo(shuffled(tc,3)).name;
         end
         SimpExp.data(tc).jitter = jitter(tc);
         SimpExp.data(tc).fix_onset = NaN;
         SimpExp.data(tc).pic_onset = NaN;
     end
 end

    SimpExp.info.ID = ID;
    SimpExp.info.Condition = COND;
    SimpExp.info.date = sprintf('%s %2.0f:%02.0f',date,d(4),d(5));
    


commandwindow;


%%
%change this to 0 to fill whole screen
DEBUG=0;

%set up the screen and dimensions

%list all the screens, then just pick the last one in the list (if you have
%only 1 monitor, then it just chooses that one)
Screen('Preference', 'SkipSyncTests', 1);

screenNumber=max(Screen('Screens'));

if DEBUG==1;
    %create a rect for the screen
    winRect=[0 0 640 480];
    %establish the center points
    XCENTER=320;
    YCENTER=240;
else
    %change screen resolution
%     Screen('Resolution',0,1024,768,[],32);
    
    %this gives the x and y dimensions of our screen, in pixels.
    [swidth, sheight] = Screen('WindowSize', screenNumber);
    XCENTER=fix(swidth/2);
    YCENTER=fix(sheight/2);
    %when you leave winRect blank, it just fills the whole screen
    winRect=[];
end

%open a window on that monitor. 32 refers to 32 bit color depth (millions of
%colors), winRect will either be a 1024x768 box, or the whole screen. The
%function returns a window "w", and a rect that represents the whole
%screen. 
[w, wRect]=Screen('OpenWindow', screenNumber, 0,winRect,32,2);

%%
%you can set the font sizes and styles here
Screen('TextFont', w, 'Arial');
%Screen('TextStyle', w, 1);
Screen('TextSize',w,30);

KbName('UnifyKeyNames');

%% Initial screen
DrawFormattedText(w,'Imagine you''re eating this food or something...','center','center',COLORS.WHITE,[],[],[],1.5);
Screen('Flip',w);
KbWait();

%% Trigger

if fmri == 1;
    DrawFormattedText(w,'Synching with fMRI: Waiting for trigger','center','center',COLORS.WHITE);
    Screen('Flip',w);
    
    scan_sec = KbTriggerWait(KEY.trigger,xkeys);
else
    scan_sec = GetSecs();
end

    

for block = 1:STIM.blocks
    for trial = 1:STIM.trials
        tcounter = (block-1)*STIM.trials + trial;
        tpx = imread(getfield(SimpExp,'data',{tcounter},'picname'));
        texture = Screen('MakeTexture',w,tpx);
        
        DrawFormattedText(w,'+','center','center',COLORS.WHITE);
        fixon = Screen('Flip',w);
        SimpExp.data(tcounter).fix_onset  = fixon - scan_sec;
        WaitSecs(SimpExp.data(tcounter).jitter);
        
        Screen('DrawTexture',w,texture);
        picon = Screen('Flip',w);
        SimpExp.data(tcounter).pic_onset = picon - scan_sec;
        WaitSecs(STIM.trialdur);
        
    end
    
    
    DrawFormattedText(w,'Press any key to continue','center',wRect(4)*9/10,COLORS.WHITE);
    Screen('Flip',w);
    KbWait();
    
end

%% Save all the data
savedir = [mdir filesep 'Results' filesep];
cd(savedir)
savename = ['SimpleExposure_Training_' num2str(ID) '.mat'];

if exist(savename,'file')==2;
    savename = ['SimpleExposure_Training_' num2str(ID) '_' sprintf('%s_%2.0f%02.0f',date,d(4),d(5)) '.mat'];
end

try
save([savedir savename],'SimpExp');
catch
    warning('Something is amiss with this save. Retrying to save in a more general location...');
    try
        save([mdir filesep savename],'SimpExp');
    catch
        warning('STILL problems saving....Try right-clicking on ''SimpExp'' and Save as...');
        SimpExp
    end
end

DrawFormattedText(w,'That concludes this task. The assessor will be with you soon.','center','center',COLORS.WHITE);
Screen('Flip', w);
WaitSecs(10);

sca

end
