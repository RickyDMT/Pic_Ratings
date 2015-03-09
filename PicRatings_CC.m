function PicRatings_CC(varargin)
% Rate all images, randomly choose 60 pics from top 80.
% Has fMRI capabilities, but mostly commented out. Need to re-add jitter to
% cross hair as it's been removed for non-scnanner usage.

global wRect w XCENTER rects mids COLORS KEYS PicRating_CC

prompt={'SUBJECT ID' 'Session' 'Do App Rating?' 'Do W Rating'}; %'fMRI? (1 = Y, 0 = N)'};
defAns={'4444' '1' '1' '1'}; %'0'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
SESS = str2double(answer{2});
doapp = str2double(answer{3});
dow = str2double(answer{4});

if isempty(SESS) || SESS < 1 || ~isnumeric(SESS);
    error('Session must be whole number, 1 - (infinity?). Please input which session this data collection represents.')
end

COLORS = struct;
COLORS.BLACK = [0 0 0];
COLORS.WHITE = [255 255 255];
COLORS.RED = [255 0 0];
COLORS.BLUE = [0 0 255];
COLORS.GREEN = [0 255 0];
COLORS.YELLOW = [255 255 0];
COLORS.rect = COLORS.GREEN;

KbName('UnifyKeyNames');

KEYS = struct;
% KEYS.LEFT=KbName('leftarrow');
% KEYS.RIGHT=KbName('rightarrow');
KEYS.ONE= KbName('1!');
KEYS.TWO= KbName('2@');
KEYS.THREE= KbName('3#');
KEYS.FOUR= KbName('4$');
KEYS.FIVE= KbName('5%');
KEYS.SIX= KbName('6^');
KEYS.SEVEN= KbName('7&');
KEYS.EIGHT= KbName('8*');
KEYS.NINE= KbName('9(');
KEYS.TEN= KbName('0)');
rangetest = cell2mat(struct2cell(KEYS));
KEYS.val = min(rangetest):max(rangetest);
KEYS.all = KEYS.ONE:KEYS.NINE;
% KEYS.trigger = KbName('''"');
    
% fmri = str2double(answer{2});

[imgdir,~,~] = fileparts(which('MasterPics_PlaceHolder.m'));    %This points to place holder .m file in MasterPics folder.

cd(imgdir);

[mfilesdir,~,~] = fileparts(which('PicRatings_CC.m'));
savefile = [imgdir filesep 'Saved_Pic_Ratings' filesep sprintf('PicRatings_CC_%d-%d.mat',ID,SESS)];

if exist(savefile,'file') == 2;
    commandwindow;
    warning('THIS FILE ALREADY EXISTS ARE YOU SURE YOU WANT TO CONTINUE?')
    overright = input('Type 1 to over-write file or 0 to cancel and enter in new info: ');
    if overright == 0;
        error('File already exists. Please double-check and/or re-enter participant number and session information.');
    end
end

PICS =struct;
    
    PICS.in.Un = dir('Unhealthy*');
    PICS.in.H = dir('Healthy*');
    
    if isempty(PICS.in.Un);
        error('Could not find pics! Make sure a folder exists called "Pics" with all the appropriate images contained therein.')
    end
    
    picnames = {PICS.in.Un.name PICS.in.H.name}';
    %1 = Healthy, 0 = Unhealthy
    pictype = num2cell([zeros(length(PICS.in.Un),1); ones(length(PICS.in.H),1)]);
    picnames = [picnames pictype];
    picnames = picnames(randperm(size(picnames,1)),:);


% jitter = BalanceTrials(length(picnames),1,[1 2 3]);

PicRating_CC = struct('filename',picnames(:,1),'PicType',picnames(:,2),'Rate_App',0); %,'Jitter',[],'FixOnset',[],'PicOnset',[],'RatingOnset',[],'RT',[]); %,'Rate_Crave',0);

% for hhh = 1:length(PicRating_CC);
%     
%     PicRating_CC(hhh).Jitter = jitter(hhh);
% end


%% Keyboard stuff for fMRI...
% If fMRI is used with ratings, uncomment this section.

% %list devices
% [keyboardIndices, productNames] = GetKeyboardIndices;
% 
% isxkeys=strcmp(productNames,'Xkeys');
% 
% xkeys=keyboardIndices(isxkeys);
% macbook = keyboardIndices(strcmp(productNames,'Apple Internal Keyboard / Trackpad'));
% 
% %in case something goes wrong or the keyboard name isn?t exactly right
% if isempty(macbook)
%     macbook=-1;
% end
% 
% %in case you?re not hooked up to the scanner, then just work off the keyboard
% if isempty(xkeys)
%     xkeys=macbook;
% end

%%
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

%% Dat Grid
[rects,mids] = DrawRectsGrid(1);
verbage = {'How appetizing is this food?' 'How much is this food worth to you?'};

%% Intro
if doapp == 1;
DrawFormattedText(w,'We are going to show you some pictures of food and have you rate how appetizing each food is.\n\n You will use a scale from 1 to 9, where 1 is "Not at all appetizing" and 9 is "Extremely appetizing."\n\nPress any key to continue.','center','center',COLORS.WHITE,50,[],[],1.5);
Screen('Flip',w);
KbWait([],3);

DrawFormattedText(w,'Please use the numbers along the top of the keyboard to select your rating.\n\nPress any key to continue.','center','center',COLORS.WHITE,50,[],[],1.5);
Screen('Flip',w);
KbWait([],3);

%% fMRI synch w/trigger
% if fmri == 1;
%     DrawFormattedText(w,'Synching with fMRI: Waiting for trigger','center','center',COLORS.WHITE);
%     Screen('Flip',w);
%     
%     scan_sec = KbTriggerWait(KEYS.trigger,xkeys);
% else
%     scan_sec = GetSecs();
% end

%%
DrawFormattedText(w,'The rating task will now begin.\n\nPress any key to continue.','center','center',COLORS.WHITE,50,[],[],1.5);
Screen('Flip',w);
KbWait([],3);
WaitSecs(1);


for x = 1:20:length(PicRating_CC);  %UPDATE TO LENGTH OF GO PICS
    for y = 1:20;
        xy = x+(y-1);
        if xy > length(PicRating_CC)
            break
        end
        
        DrawFormattedText(w,'+','center','center',COLORS.WHITE);
        Screen('Flip',w);
%         PicRating_CC(xy).FixOnset = fixon - scan_sec;
%         WaitSecs(PicRating_CC(xy).Jitter);
        WaitSecs(.25);
        
        tp = imread(getfield(PicRating_CC,{xy},'filename'));
        tpx = Screen('MakeTexture',w,tp);          
        Screen('DrawTexture',w,tpx);
%         picon = Screen('Flip',w);
%         PicRating_CC(xy).PicOnset = picon - scan_sec;
%         WaitSecs(5);
        
%         Screen('DrawTexture',w,tpx);
        drawRatings();
        DrawFormattedText(w,verbage{1},'center',(wRect(4)*.75),COLORS.BLUE);
        Screen('Flip',w);
%         PicRating_CC(xy).RatingOnset = rateon - scan_sec;
            
        FlushEvents();
            while 1
                [keyisdown, ~, keycode] = KbCheck();
                if (keyisdown==1 && any(keycode(KEYS.all)))
%                     PicRating_CC(xy).RT = rt - rateon;
                    
                    if iscell(KbName(keycode)) && numel(KbName(keycode))>1  %You have mashed 2 keys; shame on you.
                        rating = KbName(find(keycode,1));
                        rating = str2double(rating(1));
                        while isnan(rating);        %This key selection is not a number!
                            newrating = KbName(keycode);
                            for kk = 2:numel(newrating)
                                rating = str2double(newrating(kk));
                                if ~isnan(rating)
                                    break
                                elseif kk == length(KbName(keycode)) && isnan(rating);
                                    %something has gone horrible awry;
                                    warning('Trial #%d rating is NaN for some reason',xy);
                                    rating = NaN;
                                end
                            end
                        end
                    else
                        rating = KbName(find(keycode));
                        rating = str2double(rating(1));
                        
                    end
                    Screen('DrawTexture',w,tpx);
                    drawRatings(keycode);
                    DrawFormattedText(w,verbage{1},'center',(wRect(4)*.75),COLORS.BLUE);
                    Screen('Flip',w);
                    WaitSecs(.25);
                    break;
                end
            end
            %Record response here.
%             if q == 1;
%             if rating == 0; %Zero key is used for 10. Thus check and correct for when they press 0.
%                 rating = 10;
%             end
           PicRating_CC(xy).Rate_App = rating;
           Screen('Flip',w);
           FlushEvents();
%            WaitSecs(.25);

    end
    %Take a break every 20 pics.
    Screen('Flip',w);
    DrawFormattedText(w,'Press any key when you are ready to continue','center','center',COLORS.WHITE);
    Screen('Flip',w);
    KbWait([],3);
    
    if xy > length(PicRating_CC)
            break
    end
end

Screen('Flip',w);
WaitSecs(.5);

end

%% Sort & Save List of Foods.
%Sort by top appetizing ratings for each set.
fields = {'name' 'pictype' 'rating' 'chosen' 'value'}; %'jitter' 'FixOnset' 'PicOnset' 'RatingOnset' 'RT'};
presort = struct2cell(PicRating_CC)';
pre_H = presort(([presort{:,2}]==1),:);
pre_U = presort(([presort{:,2}]==0),:);

postsort_H = sortrows(pre_H,-3);    %Sort descending by column 3
postsort_U = sortrows(pre_U,-3);

%Need rando 60 out of 80 demarcated for tasks.
chosenfew = [ones(60,1); zeros(20,1)];
chosenfew_H = [chosenfew(randperm(length(chosenfew)),:); zeros(120,1)];
chosenfew_U = [chosenfew(randperm(length(chosenfew)),:); zeros(120,1)];

%Pair with sorted ratings.
postsort_H = [postsort_H num2cell(chosenfew_H) cell(length(postsort_H),1)];
postsort_U = [postsort_U num2cell(chosenfew_U) cell(length(postsort_H),1)];

%Turn back into structure
PicRating.H = cell2struct(postsort_H,fields,2);
PicRating.U = cell2struct(postsort_U,fields,2);

% savedir = [mfilesdir filesep 'Results'];

% savefilename = sprintf('PicRate_Training_%d.mat',ID);
% savefile = fullfile(savedir,savefilename);

%%
if dow == 1;
%Dat new grid:
[rects,mids] = DrawRectsGrid(2);

%List of H & U trials;
val_trial = [ones(40,1); zeros(40,1)];
val_pic = [randperm(40)'; randperm(40)'];
val_trial = [val_trial val_pic];
val_trial = val_trial(randperm(length(val_trial)),:);

% Top40 Healthy & Unhealthy (low/high)
% All pics interspersed
% One big block
% From $0 - 10 ('<$1 $2 $3....$10+')
% Instructions to describe the scale.
DrawFormattedText(w,'Next we would like you to view some of these images again and rate how much each food is worth to you. Using the number keys along the top of the key board, choose 1 if the food is worth $0 to $1 and up to 10 if the food is worth $10 or more. Note that you will press 0 (zero) at the top of the keyboard to choose "10."\n\nThere is no right or wrong answer, just choose what comes to mind first.\n\nPress any key to continue.','center','center',COLORS.WHITE,60,[],[],1.5);
Screen('Flip',w);
KbWait([],2);

for vt = 1:length(val_trial);
    DrawFormattedText(w,'+','center','center',COLORS.WHITE);
    Screen('Flip',w);
    WaitSecs(.25);
    
    valpicnum = val_trial(vt,2);
        
    if val_trial(vt,1) == 1; %If healthy trial       
        tp = imread(getfield(PicRating.H,{valpicnum},'name'));
    elseif val_trial(vt,1) == 0; %if Unhealthy trial
        tp = imread(getfield(PicRating.U,{valpicnum},'name'));
    end
    tpx = Screen('MakeTexture',w,tp); 
    Screen('DrawTexture',w,tpx);

        drawValues();
        DrawFormattedText(w,verbage{2},'center',(wRect(4)*.75),COLORS.BLUE);
        Screen('Flip',w);

            
        FlushEvents();
            while 1
                [keyisdown, ~, keycode] = KbCheck();
                if (keyisdown==1 && any(keycode(KEYS.val)))
%                     PicRating_CC(xy).RT = rt - rateon;
                    
                    rating_dos = KbName(find(keycode));
                    rating_dos = str2double(rating_dos(1));
                    
                    Screen('DrawTexture',w,tpx);
                    drawValues(keycode);
                    DrawFormattedText(w,verbage{2},'center',(wRect(4)*.75),COLORS.BLUE);
                    Screen('Flip',w);
                    WaitSecs(.25);
                    break;
                end
            end
            %Record response here.

            if rating_dos == 0; %Zero key is used for 10. Thus check and correct for when they press 0.
                rating_dos = 10;
            end
            
            if val_trial(vt,1) == 1;
                PicRating.H(valpicnum).value = rating_dos;
            elseif val_trial(vt,1) == 0;
                PicRating.U(valpicnum).value = rating_dos;
            end
                
           Screen('Flip',w);
           FlushEvents();
           WaitSecs(.25);
end

end

%% Save dat data
try
save(savefile,'PicRating');
catch
    warning('Something is amiss with this save. Retrying to save in a more general location (i.e., in same folder as PicRatings_CC.m)...\n');
    try
        savefilename = sprintf('PicRatings_CC_%d-%d.mat',ID,SESS);
        save([mfilesdir filesep savefilename],'PicRating');
        warning('Save location:  %s\n',[mfielsdir filesep savefilename]);
    catch
        warning('STILL problems saving....Look for "PicRating.mat" somewhere on the computer and rename it PicRatings_CC_%d_%d.mat\n',ID,SESS);
        warning('File might be found in: %s\n',pwd);
        save PicRating
    end
end

DrawFormattedText(w,'That concludes this task. The assessor will be with you shortly.','center','center',COLORS.WHITE);
Screen('Flip',w);
WaitSecs(5);

sca

end

%%
function [ rects,mids ] = DrawRectsGrid(appRval)
%DrawRectGrid:  Builds a grid of squares with gaps in between.

global wRect XCENTER

%Size of image will depend on screen size. First, an area approximately 80%
%of screen is determined. Then, images are 1/4th the side of that square
%(minus the 3 x the gap between images.
if appRval == 1;
    num_rects = 9;                 %How many rects?
elseif appRval == 2;
    num_rects = 10;
end

xlen = wRect(3)*.9;           %Make area covering about 90% of vertical dimension of screen.
gap = 10;                       %Gap size between each rect
square_side = fix((xlen - (num_rects-1)*gap)/num_rects); %Size of rect depends on size of screen.

squart_x = XCENTER-(xlen/2);
squart_y = wRect(4)*.8;         %Rects start @~80% down screen.

rects = zeros(4,num_rects);

% for row = 1:DIMS.grid_row;
    for col = 1:num_rects;
%         currr = ((row-1)*DIMS.grid_col)+col;
        rects(1,col)= squart_x + (col-1)*(square_side+gap);
        rects(2,col)= squart_y;
        rects(3,col)= squart_x + (col-1)*(square_side+gap)+square_side;
        rects(4,col)= squart_y + square_side;
    end
% end
mids = [rects(1,:)+square_side/2; rects(2,:)+square_side/2+5];

end

%%
function drawRatings(varargin)

global w KEYS COLORS rects mids

num_rects = 9;  
colors=repmat(COLORS.BLUE',1,num_rects);
% rects=horzcat(allRects.rate1rect',allRects.rate2rect',allRects.rate3rect',allRects.rate4rect');

%Needs to feed in "code" from KbCheck, to show which key was chosen.
if nargin >= 1 && ~isempty(varargin{1})
    response=varargin{1};
    
    key=find(response);
    if length(key)>1
        key=key(1);
    end;
    
    switch key
        
        case {KEYS.ONE}
            choice=1;
        case {KEYS.TWO}
            choice=2;
        case {KEYS.THREE}
            choice=3;
        case {KEYS.FOUR}
            choice=4;
        case {KEYS.FIVE}
            choice=5;
        case {KEYS.SIX}
            choice=6;
        case {KEYS.SEVEN}
            choice=7;
        case {KEYS.EIGHT}
            choice=8;
        case {KEYS.NINE}
            choice=9;
%         case {KEYS.TEN}
%             choice = 10;
    end
    
    if exist('choice','var')
        
        
        colors(:,choice)=COLORS.GREEN';
        
    end
end


    window=w;
   

Screen('TextFont', window, 'Arial');
Screen('TextStyle', window, 1);
oldSize = Screen('TextSize',window,35);

% Screen('TextFont', w2, 'Arial');
% Screen('TextStyle', w2, 1)
% Screen('TextSize',w2,60);



%draw all the squares
Screen('FrameRect',window,colors,rects,1);


% Screen('FrameRect',w2,colors,rects,1);


%draw the text (1-10)
for n = 1:num_rects;
    numnum = sprintf('%d',n);
    CenterTextOnPoint(window,numnum,mids(1,n),mids(2,n),COLORS.BLUE);
end


Screen('TextSize',window,oldSize);

end

function drawValues(varargin)

global w KEYS COLORS rects mids

num_rects = 10;  
colors=repmat(COLORS.BLUE',1,num_rects);
% rects=horzcat(allRects.rate1rect',allRects.rate2rect',allRects.rate3rect',allRects.rate4rect');

%Needs to feed in "code" from KbCheck, to show which key was chosen.
if nargin >= 1 && ~isempty(varargin{1})
    response=varargin{1};
    
    key=find(response);
    if length(key)>1
        key=key(1);
    end;
    
    switch key
        
        case {KEYS.ONE}
            choice=1;
        case {KEYS.TWO}
            choice=2;
        case {KEYS.THREE}
            choice=3;
        case {KEYS.FOUR}
            choice=4;
        case {KEYS.FIVE}
            choice=5;
        case {KEYS.SIX}
            choice=6;
        case {KEYS.SEVEN}
            choice=7;
        case {KEYS.EIGHT}
            choice=8;
        case {KEYS.NINE}
            choice=9;
         case {KEYS.TEN}
            choice = 10;
    end
    
    if exist('choice','var')
        
        
        colors(:,choice)=COLORS.GREEN';
        
    end
end


    window=w;
   

Screen('TextFont', window, 'Arial');
Screen('TextStyle', window, 1);
oldSize = Screen('TextSize',window,35);

% Screen('TextFont', w2, 'Arial');
% Screen('TextStyle', w2, 1)
% Screen('TextSize',w2,60);



%draw all the squares
Screen('FrameRect',window,colors,rects,1);


% Screen('FrameRect',w2,colors,rects,1);


%draw the text (1-10)
for n = 1:num_rects;
    if n == 1;
        numnum = sprintf('<$%d',n);
    elseif n == 10;
        numnum = sprintf('$%d+',n);
    else
        numnum = sprintf('$%d',n);
    end
    CenterTextOnPoint(window,numnum,mids(1,n),mids(2,n),COLORS.BLUE);
end


Screen('TextSize',window,oldSize);

end

%%
function [nx, ny, textbounds] = CenterTextOnPoint(win, tstring, sx, sy,color)
% [nx, ny, textbounds] = DrawFormattedText(win, tstring [, sx][, sy][, color][, wrapat][, flipHorizontal][, flipVertical][, vSpacing][, righttoleft])
%
% 

numlines=1;

if nargin < 1 || isempty(win)
    error('CenterTextOnPoint: Windowhandle missing!');
end

if nargin < 2 || isempty(tstring)
    % Empty text string -> Nothing to do.
    return;
end

% Store data class of input string for later use in re-cast ops:
stringclass = class(tstring);

% Default x start position is left border of window:
if isempty(sx)
    sx=0;
end

% if ischar(sx) && strcmpi(sx, 'center')
%     xcenter=1;
%     sx=0;
% else
%     xcenter=0;
% end

xcenter=0;

% No text wrapping by default:
% if nargin < 6 || isempty(wrapat)
    wrapat = 0;
% end

% No horizontal mirroring by default:
% if nargin < 7 || isempty(flipHorizontal)
    flipHorizontal = 0;
% end

% No vertical mirroring by default:
% if nargin < 8 || isempty(flipVertical)
    flipVertical = 0;
% end

% No vertical mirroring by default:
% if nargin < 9 || isempty(vSpacing)
    vSpacing = 1.5;
% end

% if nargin < 10 || isempty(righttoleft)
    righttoleft = 0;
% end

% Convert all conventional linefeeds into C-style newlines:
newlinepos = strfind(char(tstring), '\n');

% If '\n' is already encoded as a char(10) as in Octave, then
% there's no need for replacemet.
if char(10) == '\n' %#ok<STCMP>
   newlinepos = [];
end

% Need different encoding for repchar that matches class of input tstring:
if isa(tstring, 'double')
    repchar = 10;
elseif isa(tstring, 'uint8')
    repchar = uint8(10);    
else
    repchar = char(10);
end

while ~isempty(newlinepos)
    % Replace first occurence of '\n' by ASCII or double code 10 aka 'repchar':
    tstring = [ tstring(1:min(newlinepos)-1) repchar tstring(min(newlinepos)+2:end)];
    % Search next occurence of linefeed (if any) in new expanded string:
    newlinepos = strfind(char(tstring), '\n');
end

% % Text wrapping requested?
% if wrapat > 0
%     % Call WrapString to create a broken up version of the input string
%     % that is wrapped around column 'wrapat'
%     tstring = WrapString(tstring, wrapat);
% end

% Query textsize for implementation of linefeeds:
theight = Screen('TextSize', win) * vSpacing;

% Default y start position is top of window:
if isempty(sy)
    sy=0;
end

winRect = Screen('Rect', win);
winHeight = RectHeight(winRect);

% if ischar(sy) && strcmpi(sy, 'center')
    % Compute vertical centering:
    
    % Compute height of text box:
%     numlines = length(strfind(char(tstring), char(10))) + 1;
    %bbox = SetRect(0,0,1,numlines * theight);
    bbox = SetRect(0,0,1,theight);
    
    
    textRect=CenterRectOnPoint(bbox,sx,sy);
    % Center box in window:
    [rect,dh,dv] = CenterRect(bbox, textRect);

    % Initialize vertical start position sy with vertical offset of
    % centered text box:
    sy = dv;
% end

% Keep current text color if noone provided:
if nargin < 5 || isempty(color)
    color = [];
end

% Init cursor position:
xp = sx;
yp = sy;

minx = inf;
miny = inf;
maxx = 0;
maxy = 0;

% Is the OpenGL userspace context for this 'windowPtr' active, as required?
[previouswin, IsOpenGLRendering] = Screen('GetOpenGLDrawMode');

% OpenGL rendering for this window active?
if IsOpenGLRendering
    % Yes. We need to disable OpenGL mode for that other window and
    % switch to our window:
    Screen('EndOpenGL', win);
end

% Disable culling/clipping if bounding box is requested as 3rd return
% % argument, or if forcefully disabled. Unless clipping is forcefully
% % enabled.
% disableClip = (ptb_drawformattedtext_disableClipping ~= -1) && ...
%               ((ptb_drawformattedtext_disableClipping > 0) || (nargout >= 3));
% 

disableClip=1;

% Parse string, break it into substrings at line-feeds:
while ~isempty(tstring)
    % Find next substring to process:
    crpositions = strfind(char(tstring), char(10));
    if ~isempty(crpositions)
        curstring = tstring(1:min(crpositions)-1);
        tstring = tstring(min(crpositions)+1:end);
        dolinefeed = 1;
    else
        curstring = tstring;
        tstring =[];
        dolinefeed = 0;
    end

    if IsOSX
        % On OS/X, we enforce a line-break if the unwrapped/unbroken text
        % would exceed 250 characters. The ATSU text renderer of OS/X can't
        % handle more than 250 characters.
        if size(curstring, 2) > 250
            tstring = [curstring(251:end) tstring]; %#ok<AGROW>
            curstring = curstring(1:250);
            dolinefeed = 1;
        end
    end
    
    if IsWin
        % On Windows, a single ampersand & is translated into a control
        % character to enable underlined text. To avoid this and actually
        % draw & symbols in text as & symbols in text, we need to store
        % them as two && symbols. -> Replace all single & by &&.
        if isa(curstring, 'char')
            % Only works with char-acters, not doubles, so we can't do this
            % when string is represented as double-encoded Unicode:
            curstring = strrep(curstring, '&', '&&');
        end
    end
    
    % tstring contains the remainder of the input string to process in next
    % iteration, curstring is the string we need to draw now.

    % Perform crude clipping against upper and lower window borders for
    % this text snippet. If it is clearly outside the window and would get
    % clipped away by the renderer anyway, we can safe ourselves the
    % trouble of processing it:
    if disableClip || ((yp + theight >= 0) && (yp - theight <= winHeight))
        % Inside crude clipping area. Need to draw.
        noclip = 1;
    else
        % Skip this text line draw call, as it would be clipped away
        % anyway.
        noclip = 0;
        dolinefeed = 1;
    end
    
    % Any string to draw?
    if ~isempty(curstring) && noclip
        % Cast curstring back to the class of the original input string, to
        % make sure special unicode encoding (e.g., double()'s) does not
        % get lost for actual drawing:
        curstring = cast(curstring, stringclass);
        
        % Need bounding box?
%         if xcenter || flipHorizontal || flipVertical
            % Compute text bounding box for this substring:
            bbox=Screen('TextBounds', win, curstring, [], [], [], righttoleft);
%         end
        
        % Horizontally centered output required?
%         if xcenter
            % Yes. Compute dh, dv position offsets to center it in the center of window.
%             [rect,dh] = CenterRect(bbox, winRect);
            [rect,dh] = CenterRect(bbox, textRect);
            % Set drawing cursor to horizontal x offset:
            xp = dh;
%         end
            
%         if flipHorizontal || flipVertical
%             textbox = OffsetRect(bbox, xp, yp);
%             [xc, yc] = RectCenter(textbox);
% 
%             % Make a backup copy of the current transformation matrix for later
%             % use/restoration of default state:
%             Screen('glPushMatrix', win);
% 
%             % Translate origin into the geometric center of text:
%             Screen('glTranslate', win, xc, yc, 0);
% 
%             % Apple a scaling transform which flips the direction of x-Axis,
%             % thereby mirroring the drawn text horizontally:
%             if flipVertical
%                 Screen('glScale', win, 1, -1, 1);
%             end
%             
%             if flipHorizontal
%                 Screen('glScale', win, -1, 1, 1);
%             end
% 
%             % We need to undo the translations...
%             Screen('glTranslate', win, -xc, -yc, 0);
%             [nx ny] = Screen('DrawText', win, curstring, xp, yp, color, [], [], righttoleft);
%             Screen('glPopMatrix', win);
%         else
            [nx ny] = Screen('DrawText', win, curstring, xp, yp, color, [], [], righttoleft);
%         end
    else
        % This is an empty substring (pure linefeed). Just update cursor
        % position:
        nx = xp;
        ny = yp;
    end

    % Update bounding box:
    minx = min([minx , xp, nx]);
    maxx = max([maxx , xp, nx]);
    miny = min([miny , yp, ny]);
    maxy = max([maxy , yp, ny]);

    % Linefeed to do?
    if dolinefeed
        % Update text drawing cursor to perform carriage return:
        if xcenter==0
            xp = sx;
        end
        yp = ny + theight;
    else
        % Keep drawing cursor where it is supposed to be:
        xp = nx;
        yp = ny;
    end
    % Done with substring, parse next substring.
end

% Add one line height:
maxy = maxy + theight;

% Create final bounding box:
textbounds = SetRect(minx, miny, maxx, maxy);

% Create new cursor position. The cursor is positioned to allow
% to continue to print text directly after the drawn text.
% Basically behaves like printf or fprintf formatting.
nx = xp;
ny = yp;

% Our work is done. If a different window than our target window was
% active, we'll switch back to that window and its state:
if previouswin > 0
    if previouswin ~= win
        % Different window was active before our invocation:

        % Was that window in 3D mode, i.e., OpenGL rendering for that window was active?
        if IsOpenGLRendering
            % Yes. We need to switch that window back into 3D OpenGL mode:
            Screen('BeginOpenGL', previouswin);
        else
            % No. We just perform a dummy call that will switch back to that
            % window:
            Screen('GetWindowInfo', previouswin);
        end
    else
        % Our window was active beforehand.
        if IsOpenGLRendering
            % Was in 3D mode. We need to switch back to 3D:
            Screen('BeginOpenGL', previouswin);
        end
    end
end

return;
end

