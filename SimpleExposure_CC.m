function SimpleExposure_CC(varargin)
% Notes on 2/19/15
%Ratings file location: Make sure ratings files are in folder called "Ratings" within same folder as SimpleExposure_CC.m
%Pics folder path: Adjust accordingly Make sure THIS is true too.
%Only using session 1 ratings, regardless of fMRI session?: Assumes only uses ratings from Session 1. Change as needed.
%Check Pic size & adjust imgrect accordingly.
%Different sizes for different pic types?  Adjust accordingly.

global KEY COLORS w wRect XCENTER YCENTER PICS STIM SimpExp trial

%This is for food exposure!

prompt={'SUBJECT ID' 'Condition' 'Session' 'fMRI (1 = Yes, 0 = No)'};
defAns={'4444' '1' '1' '0'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
COND = str2double(answer{2});
fmri = str2double(answer{4});
SESS = str2double(answer{3});
% prac = str2double(answer{4});


% rng(ID); %Seed random number generator with subject ID
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
STIM.blocks = 2;
STIM.trials = 50;
STIM.totes = STIM.blocks*STIM.trials;
STIM.H_trials = 40;
STIM.UnH_trials = 40;
STIM.neut_trials = 20;
STIM.trialdur = 5;
STIM.jitter = [2 3 4];
% STIM.jitter = [.5 1 1.5];


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
[mdir,~,~] = fileparts(which('SimpleExposure_CC.m'));

savedir = [mdir filesep 'Results' filesep];
savename = sprintf('SimpleExposure_CC_%d-%d.mat',ID,SESS);
savefile = [savedir filesep savename];
% Check if file exists...

if exist(savefile,'file') == 2;
    error('File already exists. Please double-check and/or re-enter participant number and session information.');
end

picratefolder = fullfile(mdir,'Ratings');   %XXX: Make sure ratings files are in folder called "Ratings" within same folder as SimpleExposure_CC.m
imgdir = fullfile(mdir,'Pics');             %XXX: Adjust accordingly Make sure THIS is true too.
% imgdir = '/Users/canelab/Documents/StudyTasks/MasterPics';    %for testing purposes

randopics = 0;

try
    cd(picratefolder)
catch
    error('Could not find and/or open the folder that contains the image ratings.');
end


if COND ==1;    %If EXP condition!
    filen = sprintf('PicRatings_CC_%d-1.mat',ID); %XXX: Assumes only uses ratings from Session 1. Change as needed.
    try
        p = open(filen);
    catch
        warning('Attemped to open file called "%s" for Subject #%d. Could not find and/or open this training rating file. Double check that you have typed in the subject number appropriately.',filen,ID);
        commandwindow;
        randopics = input('Would you like to continue with a random selection of images? [1 = Yes, 0 = No]');
        if randopics == 1
            cd(imgdir)
            p = struct;
            p.PicRating.go = dir('Unhealthy*');
            p.PicRating.no = dir('Healthy*');
            
            PICS.in.H = struct('name',{p.PicRating.go(randperm(40)).name}');
            PICS.in.UnH = struct('name',{p.PicRating.no(randperm(40)).name}');
            
        else
            error('Task cannot proceed without images. Contact Erik (elk@uoregon.edu) if you have continued problems.')
        end
        
    end
    cd(imgdir);
    
    if randopics == 0;
        PICS.in.H = struct('name',{p.PicRating.H.name}');
        PICS.in.UnH = struct('name',{p.PicRating.U.name}');
        
    end
else
    cd(imgdir)
%     p = struct;
    PICS.in.H = dir('Unhealthy*');
    PICS.in.UnH = dir('Healthy*');
end

    

% cd(imgdir);

neutpics = dir('water*');

%Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(neutpics) || isempty(PICS.in.H) || isempty(PICS.in.UnH)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end

%% Fill in rest of pertinent info
SimpExp = struct;


    %1 = hi cal food, 2 = low cal food, 0 = water
    pictype = [ones(STIM.H_trials,1); repmat(2,STIM.UnH_trials,1); zeros(STIM.neut_trials,1)];

if COND == 1    
    %1 = in training tasks, 0 = not in training tasks
    trainpic = [repmat([ones(20,1); zeros(20,1)],2,1); zeros(20,1)];

    if randopics == 1
        %Just choose some random pics
        trainpic = zeros(length(pictype),1);
        piclist = [randperm(length(PICS.in.H),40)'; randperm(length(PICS.in.UnH),40)'; randperm(length(neutpics),STIM.neut_trials)'];

    else
        %1 = in training tasks, 0 = not in training tasks
        trainpic = [repmat([ones(20,1); zeros(20,1)],2,1); zeros(20,1)];

        %Make long list of randomized #s to represent each pic
        %Need random 20 from top 80 pics + random ordering of next 20 pics
        %Repeat for low cal food...
        pics_chosen_H = [p.PicRating.H.chosen];    
        pics_intrain_H = find(pics_chosen_H == 1);
        pics_outtrain_H = find(pics_chosen_H == 0);

        pics_chosen_U = [p.PicRating.U.chosen];    
        pics_intrain_U = find(pics_chosen_U == 1);
        pics_outtrain_U = find(pics_chosen_U == 0);

        piclist = [pics_intrain_H(randperm(length(pics_intrain_H),20))'; pics_outtrain_H(randperm(20))'; pics_intrain_U(randperm(length(pics_intrain_U),20))'; pics_outtrain_U(randperm(20))'; randperm(length(neutpics),STIM.neut_trials)'];

    end
else
    %Otherwise, all pics are NOT in training tasks and are thus randomly
    %selected from entire list of possible pics.
    
    trainpic = zeros(length(pictype),1);
    piclist = [randperm(length(PICS.in.H),40)'; randperm(length(PICS.in.UnH),40)'; randperm(length(neutpics),STIM.neut_trials)'];
end

%Concatenate these into a long list of trial types.
trial_types = [pictype trainpic piclist];
shuffled = trial_types(randperm(size(trial_types,1)),:);

jitter = BalanceTrials(STIM.totes,1,STIM.jitter);

if length(jitter) > length(trial_types)
    jitter = jitter(1:length(trial_types),:);
end


 for x = 1:STIM.blocks
     for y = 1:STIM.trials;
         tc = (x-1)*STIM.trials + y;
         SimpExp.data(tc).block = x;
         SimpExp.data(tc).trial = y;
         SimpExp.data(tc).pictype = shuffled(tc,1);
         SimpExp.data(tc).training = shuffled(tc,2);
         if shuffled(tc,1) == 1
            SimpExp.data(tc).picname = PICS.in.H(shuffled(tc,3)).name;
         elseif shuffled(tc,1) == 0
             SimpExp.data(tc).picname = neutpics(shuffled(tc,3)).name;
         elseif shuffled(tc,1) == 2;
             SimpExp.data(tc).picname = PICS.in.UnH(shuffled(tc,3)).name;
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
Screen('TextSize',w,35);

KbName('UnifyKeyNames');

%% How big to make image;

%image should take up X% of vertical space.
halfside = fix((wRect(4)*.75)/2);
%pics are naturally 1/3 Wider than tall...
x_halfside = fix((wRect(4)*.75*(1+1/3))/2); %XXX: CHECK PIC SIZE FOR PROPER PROPORTION W:H.

imgrect = [XCENTER-x_halfside; YCENTER-halfside; XCENTER+x_halfside; YCENTER+halfside];
imgrect_neut = [XCENTER-halfside; YCENTER-halfside; XCENTER+halfside; YCENTER+halfside];

    
%% Initial screen
DrawFormattedText(w,'In this task, we will show you a series of images of foods. We want you to imagine you''re eating the food that is present on the screen.\n\nPress any key when you are ready to begin.','center','center',COLORS.WHITE,60,[],[],1.5);
Screen('Flip',w);
KbWait([],2);

%% Trigger

if fmri == 1;
    DrawFormattedText(w,'Synching with fMRI: Waiting for trigger','center','center',COLORS.WHITE);
    Screen('Flip',w);
    
    scan_sec = KbTriggerWait(KEY.trigger,xkeys);
else
    scan_sec = GetSecs();
end

%%
for block = 1:STIM.blocks
    old = Screen('TextSize',w,60);
    for trial = 1:STIM.trials
        tcounter = (block-1)*STIM.trials + trial;
        
        tpx = imread(getfield(SimpExp,'data',{tcounter},'picname'));
        texture = Screen('MakeTexture',w,tpx);
        
        DrawFormattedText(w,'+','center','center',COLORS.WHITE);
        fixon = Screen('Flip',w);
        SimpExp.data(tcounter).fix_onset  = fixon - scan_sec;
        WaitSecs(SimpExp.data(tcounter).jitter);
        
        %XXX: If different size pix for different trial types (i.e.,
        %neutral are oddly shaped), do if statement for imgrect);
        if SimpExp.data(tcounter).pictype == 0;
            Screen('DrawTexture',w,texture,[],imgrect_neut);
        else
            Screen('DrawTexture',w,texture,[],imgrect);
        end
        
        picon = Screen('Flip',w);
        SimpExp.data(tcounter).pic_onset = picon - scan_sec;
        WaitSecs(STIM.trialdur);
        
    end
    
    Screen('TextSize',w,old);
    
    if block < STIM.blocks;
        interblocktext = sprintf('That concludes Block %d.\n\nPress any key to continue to Block %d when you are ready.',block,block+1);
        DrawFormattedText(w,interblocktext,'center','center',COLORS.WHITE);
        Screen('Flip',w);
        KbWait([],2);
    end
     
    
end

%% Save all the data
% savedir = [mdir filesep 'Results' filesep];
% cd(savedir)
% savename = sprintf('SimpleExposure_CC_%d-%d.mat',ID,SESS);

if exist(savename,'file')==2;
    savename = sprintf('SimpleExposure_CC_%d-%d_%s_%2.0f%02.0f.mat',ID,SESS,date,d(4),d(5));
end

try
save([savedir savename],'SimpExp');
catch
    warning('Something is amiss with this save. Retrying to save in a more general location...');
    try
        save([mdir filesep savename],'SimpExp');
    catch
        warning('STILL problems saving....Try right-clicking on ''SimpExp'' and Save as...');
        save SimpExp
    end
end

DrawFormattedText(w,'That concludes this task. The assessor will be with you soon.','center','center',COLORS.WHITE);
Screen('Flip', w);
WaitSecs(5);

sca

end
