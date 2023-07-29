


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         Ultrasound Neuromodulation MAIN Script.  v1.3  Nov 19, 2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Code to connect to TPO .  Do not edit!
disp('Connecting to TPO....');
addpath('TPOcommands') % adds functions for issuing TPO commands to workspace
if exist('serialTPO', 'var') % Code to clear com port if code was aborted
    try
        fclose(serialTPO);
        delete(serialTPO);
    catch
        delete(serialTPO);
       
    end
end
newobjs = instrfind;

if ~isempty(newobjs)
    fclose(newobjs);
end

try
    COMports = comPortSniff; % cell containing string identifier of com port
catch
    error('No COM ports found, please check TPO');
end

% Removes any empty cells
COMports = COMports(~cellfun('isempty',COMports));
len = length(COMports(:));
COMports = reshape(COMports,[len/2 2]);
tempInd = strfind(COMports(:,1), 'Arduino Due');
indTPO = find(not(cellfun('isempty', tempInd)));
if isempty(indTPO)
    error( 'No TPO detected, please check your USB and power connections')
end
indTPO = indTPO(1); 
disp(['COM port: ' num2str(indTPO) '-' COMports{indTPO,1}]);
serialTPO = serial(['COM' num2str(COMports{indTPO,2})],'BaudRate', 9600,'DataBits', 8, 'Terminator', 'CR');
fopen(serialTPO);
pause(3)
reply = fscanf(serialTPO);
disp(reply)
reply = fscanf(serialTPO);
disp(reply)
setLocal(serialTPO,0); %% Changes TPO control to script commands. Wont respond to most front panel parameters

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% EDITABLE SCRIPT START %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Depth = 30;  % in mmsj
xdrCenterFreq = 500;   % in kilohertz
Power = 20;  % in Watts


burstLength = 20000 ;   %  in microseconds
PRF = 5;  % in Hertz
SonicDuration = 80;   % Sonication Duration in seconds

%% white noise mask parameters
Fs = 100000;  % sampling frequency in Hz
t = 80; % signal duration in seconds
y = randn(t*Fs,1); % generate White noise of duration te

%% Sets burst parameter commands to TPO

setFreq(serialTPO,0,xdrCenterFreq); % with '0' as the second argument, freq is assigned to all channels
setPower(serialTPO,Power);             % always set power after frequency or you may limit TPO
setBurst(serialTPO,burstLength);
setPRF(serialTPO,PRF);             % in Hz
setTimer(serialTPO,(SonicDuration*100));              % Timer, also adjusts for the 10 ms error of TPO
setDepth(serialTPO,Depth);


prompt = 'Please enter a unique filename ID:   ';
numba = input(prompt,'s');
prompt2 = 'Please enter sheet number:   ';
sheet = input(prompt2,'s');
filename=[num2str(numba),'_Real_tbFUS_',date,'_',num2str(sheet),'.xlsx'];
disp('Press a key to view Basic parameters....CHECK VOLUME IS COMFORTABLE FOR SUBJECT!!')  
disp(' ');
disp(' ');        
pause;  %wait for user to press key 

disp(['Depth = ', num2str(Depth), 'mm'])
disp(['CenterFreq = ', num2str(xdrCenterFreq), 'kHz']) 
disp('--------------------------')
disp(['Power =', num2str(Power)])
disp(['SonicDuration = ', num2str(SonicDuration), 's'])
disp(['burstLength = ', num2str(burstLength), 'us'])
disp(['PRF = ', num2str(PRF), 'Hz'])


disp('Press ANY KEY to SONICATE....') 
pause;  %wait for user to press key 
sound(y,Fs,24); %play sound
startTPO(serialTPO);

 M = cell(2,5); % create blank matrix
M{1,1} = 'NumberBursts';
M{1,2} = 'Power';
M{1,3} = 'SonicDuration (seconds)';
M{1,4} = 'PRF';
M{1,5} = 'burstLength (microseconds)';

   %M{i+1,1}=i;
M{2,1}=400;
M{2,2}=Power;
M{2,3}=SonicDuration;
M{2,4}=PRF;
M{2,5}=burstLength;
%%
tic
it = 1;
while ( toc < SonicDuration+0.2 )

    if toc > 0.2*it
        disp([num2str(it), '-']);
        it = it + 1;
    end
end
%%

stopTPO(serialTPO)

  warning( 'off', 'MATLAB:xlswrite:AddSheet' ) ;  %save raw burst parameters
  xlswrite(filename,M)
   disp(['Data Saved Successfully in ' filename])


%% Changes TPO control to front panel control
setLocal(serialTPO,1);
clc
clear

