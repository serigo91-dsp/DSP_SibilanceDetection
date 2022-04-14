

[data1,Fs1] = audioread('n1.wav'); %Take the specs of the first audio file
numberOfSamples1 = length(data1);% take the sample number of the first audio file
nameF = ["n1.wav","n2.wav","n3.wav","n4.wav","n5.wav","n6.wav","n7.wav","n8.wav","n10.wav","n11.wav","n12.wav","n13.wav","n14.wav","n15.wav","n16.wav","n17.wav","n18.wav","n19.wav","n20.wav","n21.wav","n22.wav","n23.wav","n24.wav","y1.wav","y2.wav","y3.wav","y4.wav","y5.wav","y6.wav","y7.wav","y8.wav","y9.wav","y10.wav","y11.wav","y12.wav","y13.wav","y14.wav","y15.wav","y16.wav","y17.wav","y18.wav","y19.wav","y20.wav","y21.wav","y22.wav","y23.wav","y24.wav","y25.wav"]; %Create array of the different audio files names
fileCount = length(nameF);
dataM = zeros(fileCount,numberOfSamples1); %Create an empty matrix with optimum size for storage of 1st Audio Files 




%% This code is to create a matrix of zeros which is large enough to store all of the audio files in.
for k = 1:fileCount
   nameLoop = nameF(k);
    
[dataS,Fs] = audioread(nameLoop);% Read audio files
numberOfSamples = length(dataS);% lenght of the samples
j = size(dataM,2);

 if numberOfSamples > j %If statement which tell the code to increase size of data matrix if the data lenght size is bigger.
    dataM = zeros(fileCount,numberOfSamples);
  else
end

 
end


%% This code will load all of the audio data into the specified matrix, padding with zeros if the data is too small
for i = 1:fileCount
   nameLoop2 = nameF(i);
   
 [dataS,Fs] = audioread(nameLoop2); %Begin loading the audio files onto the big matrix, 
 numberOfSamples = length(dataS);
 T = dataS.';
 if numberOfSamples < j %if loop which will decide if the file is shorter to pad it with zeros
     
 paddedData = padarray(T,[0 (j-numberOfSamples)],0,'post');
 
dataM(i,:) = paddedData;
 
 else % if the file is big enough then we will just load it into the matrix
     dataM(i,:) = dataS;
 end

end
%% Here we will normalise the gain of the audio. Code by Audio Normalization
%by MATLAB version 1.1.0 (67.2 KB) by Yi-Wen Chen
amplification = 0.75;

for n = 1:fileCount
if max(dataM(n,:)) > abs(min(dataM(n,:)))
    dataM(n,:) = dataM(n,:)*(amplification/max(dataM(n,:)));
     disp('Normalizing Up')
else
    dataM(n,:) = dataM(n,:)*((-amplification)/min(dataM(n,:)));
    disp('Normalizing Down')
end
end




%% Creating two matrix for Yes and No and begin setting the parameters for the FFT
powerMN = zeros(23,length(dataM));
powerMY = zeros((fileCount-23),length(dataM));
filteredDataNHP = zeros(23,length(dataM));
filteredDataYHP = zeros((fileCount-23),length(dataM));
filteredDataNLP = zeros(23,length(dataM));
filteredDataYLP = zeros((fileCount-23),length(dataM));
fft_filteredDataNHP = zeros(23,length(dataM));
fft_filteredDataYHP = zeros((fileCount-23),length(dataM));
fft_filteredDataNLP = zeros(23,length(dataM));
fft_filteredDataYLP = zeros((fileCount-23),length(dataM));



nyFreq = Fs/2; % setting nyquist frequency
fftbins = (0:length(dataM)); % setting the number of FFT bins
freqToPlot = fftbins*Fs/length(dataM); %the frequency bin size is worked out here.
nyplot = ceil(nyFreq);

 o = 1;
 q = 1;
%% Calculate the FFT of each file and load into the either Yes/No Matrix
for f = 1:fileCount
 
   
fftSound = fft(dataM(f,:)/numel(dataM(f,:))); % generating the FFT of the data matrix

powerSound = fftSound.*conj(fftSound); % getting the power spectrum by generating the absolute value

    if f <= 23 
        
        powerMN(o,:) = powerSound;
             o = o+1;
    else
        
        powerMY(q,:) = powerSound;
               q = q+1;
        
    end
end

%% Get the mean of the yes and no power then plot it
powerMeanN = rms(powerMN);
powerMeanY = rms(powerMY);

figure(1);
semilogy(freqToPlot(1:nyplot),powerMeanN(1:nyplot)); hold on;
semilogy(freqToPlot(1:nyplot),powerMeanY(1:nyplot)); hold on;
legend('No','Yes');
title('Power Spectrum')
ylabel('Magnitude (dB)'); xlabel('Frequency (Hz)');

hold off

o = 1;
q = 1;
 
%% Apply the filters to the audio signal 
for c = 1:fileCount
signal = dataM(c,:);

filteredSignalHP = filter(FIR_HP,signal); %High Pass Filter for the sibilance check 
filteredSignalLP = filter(FIR_LP,signal);%Low pass for the normailsed signal 
fft_filtered_sighp = fft(filteredSignalHP/numel(filteredSignalHP));
fft_filtered_siglp = fft(filteredSignalLP/numel(filteredSignalLP));
abs_fft_filtered_sighp = fft_filtered_sighp.*conj(fft_filtered_sighp);
abs_fft_filtered_siglp = fft_filtered_siglp.*conj(fft_filtered_siglp);

if c <= 23 
        
       fft_filteredDataNHP(o,:) = abs_fft_filtered_sighp;
       fft_filteredDataNLP(o,:) = abs_fft_filtered_siglp;
       filteredDataNHP(o,:) = filteredSignalHP;
       filteredDataNLP(o,:) = filteredSignalLP;
             o = o+1;
    else
        
        filteredDataYHP(q,:) = filteredSignalHP;
        filteredDataYLP(q,:) = filteredSignalLP;
        fft_filteredDataYHP(q,:) = abs_fft_filtered_sighp;
        fft_filteredDataYLP(q,:) = abs_fft_filtered_siglp;
               q = q+1;
        
    end
end
%% we will work our the ration between the mean of the 2 signals for the high frequencies
fft_filtered_signal_mean_no_hp = rms(fft_filteredDataNHP);
fft_filtered_signal_mean_yes_hp = rms(fft_filteredDataYHP);

filtered_signal_mean_no_hp = rms(filteredDataNHP);
filtered_signal_mean_yes_hp = rms(filteredDataYHP);

power_no_hp = bandpower(filtered_signal_mean_no_hp);
power_yes_hp = bandpower(filtered_signal_mean_yes_hp);
power_differencehp = power_no_hp/power_yes_hp; 

%% Here we will do the same for the low frequencies

fft_filtered_signal_mean_no_lp = rms(fft_filteredDataNLP);
fft_filtered_signal_mean_yes_lp = rms(fft_filteredDataYLP);

filtered_signal_mean_no_lp = rms(filteredDataNLP);
filtered_signal_mean_yes_lp = rms(filteredDataYLP);

power_no_lp = bandpower(filtered_signal_mean_no_lp);
power_yes_lp = bandpower(filtered_signal_mean_yes_lp);
power_differencelp = power_no_lp/power_yes_lp; 

power_difference_yes = power_yes_hp/power_yes_lp;
power_difference_no = power_no_hp/power_no_lp;


figure(2);
semilogy(freqToPlot(1:nyplot),fft_filtered_signal_mean_no_hp(1:nyplot)); hold on;
semilogy(freqToPlot(1:nyplot),fft_filtered_signal_mean_yes_hp(1:nyplot)); hold on;
semilogy(freqToPlot(1:nyplot),fft_filtered_signal_mean_no_lp(1:nyplot)); hold on;
semilogy(freqToPlot(1:nyplot),fft_filtered_signal_mean_yes_lp(1:nyplot)); hold on;
legend('No High Pass','Yes High Pass','No Low Pass','Yes Low Pass');
title('Power Spectrum of Filtered Signal');
ylabel('Magnitude (dB)'); xlabel('Frequency (Hz)');
hold off

 %% We will now use an if statement to determine wether the word is yes or no.
bar_power = zeros(1,fileCount);
for d = 1:fileCount

%g = randi([1 fileCount],1,1); %For testing purposes

test_signal = dataM(d,:);
test_signal_HI = filter(FIR_HP,test_signal);
test_signal_LO = filter(FIR_LP,test_signal);

test_signal_HI_power = bandpower(test_signal_HI);
test_signal_LO_power = bandpower(test_signal_LO);


test_signal_power_ratio = (test_signal_HI_power/test_signal_LO_power);
isSibilancePresent = test_signal_power_ratio > 0.004;
sound_number = num2str(d);
text_power_test_signal = num2str(test_signal_power_ratio);
   if isSibilancePresent
       
        disp(['Yes on Sound ', sound_number, ' with power ', text_power_test_signal])
        %sound(test_signal, Fs);
        pause(3);
 
   else
        disp(['No on Sound ', sound_number, ' with power ', text_power_test_signal])
        %sound(test_signal, Fs);
        pause(3);
    
   end
 bar_power(1,d) = test_signal_power_ratio;
%    
 end
% 
% 
 figure(4);
 semilogy(bar_power,'b--o'); hold on;
 line([1,fileCount],[0.004,0.004]); hold on;
 title('LP/HP Filter Power Ratio')
 legend('Power Ratios','Threshold')
 hold off;
% 
% 
