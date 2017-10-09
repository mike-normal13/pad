//
//  Pad.swift
//  Sampler_App
//
//  Created by mike on 3/12/17.
//  Copyright © 2017 Team_Audio_Mobile. All rights reserved.
//

import UIKit
import AVFoundation

// this file encompases the model and view architecture of the Pad concept.
//  we have the view component and the model components of the pad residing in distant parts of the class hierarchy.

/** represents the view and control component of the Pad concept 
        An array of this class will be owned by the BankVC*/
class PadView: UIView, UIGestureRecognizerDelegate
{
    /** Yellow, Blue, Orange, Purple, Green.
            5 possible RGB colors for five possible simultaneous touches. */
    private var _colorArray = ([CGFloat(255.0), CGFloat(255.0), CGFloat(5.0)], // yellow
                               [CGFloat(5.0), CGFloat(5.0), CGFloat(255.0)],    // blue
                               [CGFloat(255.0), CGFloat(128.0), CGFloat(5.0)],  // orange
                               [CGFloat(127.0), CGFloat(5.0), CGFloat(255.0)],  //Purple
                               [CGFloat(5.0), CGFloat(255.0), CGFloat(5.0)]); //Green
    
    private var _bgcRed: CGFloat = 255;
    var bgcRed: CGFloat
    {
        get{    return _bgcRed;    }
        set
        {
            _bgcRed = newValue;
            backgroundColor = UIColor(red: _bgcRed, green: _bgcGreen, blue: _bgcBlue, alpha: 1.0);
        }
    }
    
    private var _bgcGreen: CGFloat = 255;
    var bgcGreen: CGFloat
    {
        get{    return _bgcGreen;   }
        set
        {
            _bgcGreen = newValue;
            backgroundColor = UIColor(red: _bgcRed, green: _bgcGreen, blue: _bgcBlue, alpha: 1.0);
        }
    }
    
    private var _bgcBlue: CGFloat = 255;
    var bgcBlue: CGFloat
    {
        get{    return _bgcBlue;    }
        set
        {
            _bgcBlue = newValue;
            backgroundColor = UIColor(red: _bgcRed, green: _bgcGreen, blue: _bgcBlue, alpha: 1.0);
        }
    }
    
    // TODO: we might not need this if we implement  a parent protocol heirarchy.....
    /** control will send appropriate signal if self is touched or released */
    private var _touchDownControl: UIControl = UIControl();
    
    /** displays the name of the file loaded into the pad */
    private var _fileLabel: UILabel! = nil;
    var fileLabel: UILabel{ get{    return _fileLabel;  }   }
    
    /** denotes whether self was the last touched pad */
    private var _lastTouched: Bool = false;
    var lastTouched: Bool{    get{    return _lastTouched;    }   }
    
    /** reflects whether this has a sound loaded */
    private var _isLoaded: Bool = false;
    var isLoaded: Bool
    {
        get{    return _isLoaded;   }
        set{    _isLoaded = newValue;   }
    }
    
    private var _padNumber: Int = -1;
    var padNumber: Int
    {
        get{    return _padNumber;  }
        set{    _padNumber = newValue;  }
    }
    
    weak var delegate: ParentPadViewProtocol! = nil;
    private var _opQueue: OperationQueue! = OperationQueue();
    
    /** users may touch more than one pad at a time in any given bankVC,
        the first touched pad will have an index of 0,
            the second simultenously touched pad will have an index of 1,
                and so on */
    private var _touchIndex: Int = 0;
    var touchIndex: Int
    {
        get{    return _touchIndex; }
        set{    _touchIndex = newValue; }
    }
    
    /** the current play volume of this Pad's corresponding model passed down by the MasterSoundMod,
            used to adjust the View's color */
    private var _currentPlayVolume: Float = 0;
    var currentPlayVolume: Float
    {
        get{    return _currentPlayVolume;  }
        set{    _currentPlayVolume = newValue;  }
    }
    
    /** helps with reseting pad color schemes in case the user has a pad pressed in the bankVC while,
            at the same time choosing an action which will cause the bank VC to dissapear.
                e.g. pressing a pad and a bank switch button at the same time */
    private var _isTouched: Bool = false;
    var isTouched: Bool
    {
        get{    return _isTouched;  }
        set{    _isTouched = newValue;  }
    }
    
    private var _reversePinchGestureRecognizer: UIPinchGestureRecognizer! = nil
    private var _reversePinchVelocityThreshold: CGFloat = 0.5;
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.frame = frame;
        backgroundColor = .black;
        //_opQueue = OperationQueue();
        
        // TODO: handle setting up the file name label. addSubview.....
        
        _reversePinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handleReversePinchGesture));
        _reversePinchGestureRecognizer.delegate = self;
        
        addGestureRecognizer(_reversePinchGestureRecognizer);
    }
    
    convenience init(frame: CGRect, padNumber: Int)
    {
        self.init(frame: frame);
        _padNumber = padNumber;
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder);
        //fatalError("init(coder:) has not been implemented");
        
        backgroundColor = .black
        
        _reversePinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handleReversePinchGesture));
        _reversePinchGestureRecognizer.delegate = self;
        
        addGestureRecognizer(_reversePinchGestureRecognizer);
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        _isTouched = true;
        delegate.padTouchDown(number: self._padNumber);
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        _isTouched = false;
        self.delegate.padTouchUp(number: self._padNumber);
    }
    
    /** we are curretnly expecting this to be called upon the 6th siumltaneous touch */
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        _isTouched = false;
        self.delegate.sixthTouch(number: self._padNumber);
    }
    
    func setBackgroundColor(volumeLevel: Float)
    {
        if(_touchIndex == 1)    // yellow
        {
            bgcRed = _colorArray.0[0] * CGFloat(volumeLevel)
            bgcGreen = _colorArray.0[1] * CGFloat(volumeLevel)
            bgcBlue = _colorArray.0[2] * CGFloat(volumeLevel)
        }
        else if(_touchIndex == 2)   //blue
        {
            bgcRed = _colorArray.1[0] * CGFloat(volumeLevel)
            bgcGreen = _colorArray.1[1] * CGFloat(volumeLevel)
            bgcBlue = _colorArray.1[2] * CGFloat(volumeLevel)
        }
        else if(_touchIndex == 3)   // orange
        {
            bgcRed = _colorArray.2[0] * CGFloat(volumeLevel)
            bgcGreen = _colorArray.2[1] * CGFloat(volumeLevel)
            bgcBlue = _colorArray.2[2] * CGFloat(volumeLevel)
        }
        else if(_touchIndex == 4) // purple
        {
            bgcRed = _colorArray.3[0] * CGFloat(volumeLevel)
            bgcGreen = _colorArray.3[1] * CGFloat(volumeLevel)
            bgcBlue = _colorArray.3[2] * CGFloat(volumeLevel)
        }
        else if(_touchIndex == 5)   // green
        {
            bgcRed = _colorArray.4[0] * CGFloat(volumeLevel)
            bgcGreen = _colorArray.4[1] * CGFloat(volumeLevel)
            bgcBlue = _colorArray.4[2] * CGFloat(volumeLevel)
        }
    }
    
    @objc func handleReversePinchGesture()
    {
        print("pinch velocity: " + _reversePinchGestureRecognizer.velocity.description)
        //print("pinch scale: " + _reversePinchGestureRecognizer.scale.description)
        if(_reversePinchGestureRecognizer.velocity > _reversePinchVelocityThreshold)
        {   delegate.pinchMoveToPadConfig(number: _padNumber);  }
    }
    
}//----------------------------------------------------- END OF PADVIEW CLASS ---------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------

/** represents the model for the Pad concept 
        several arrays of these will be owned by the master sound mod */
class PadModel
{
    // debug
    //private lazy var _audioSession = AVAudioSession.sharedInstance();
    
    /** number of audio outputs provided by the device */
    private var _hardwareOutputs: Int;
    
    /** 0 - 7, for now..... */
    private var _padNumber: Int = -1;
    private var _bankNumber: Int = -1;
        
    // TODO; tenative.....
    /** name of the file loaded into this */
    private var _fileName: String = "";
    var fileName: String{   get{    return _fileName;   }   }
    
    /** actual file*/
    private lazy var _file = AVAudioFile();
    var file: AVAudioFile
    {
        get{    return _file;   }
        set
        {
            _file = newValue;
            _fadeSampleCount = (_file.fileFormat.sampleRate * _fadeTime) / 1000.0;
            
            _startingFrame = 0;
            _endingFrame = _file.length;
            
            if(_fileBuffer == nil){ initBuffer();   }
            
            updateBuffer();
        }
    }
    /** path to loaded audio file */
    var filePath: URL   {   get{    return _file.url.appendingPathComponent("/" + _fileName);   }    }
    
    //  TODO:   can we go down to one playerNode????
    //  TODO: to be shared amongst all player nodes in playerNodeArray
    private var  _fileBuffer: AVAudioPCMBuffer! = nil;
    
    /** number of frames in the file buffer */
    private var _totalFrameCount: AVAudioFramePosition! = nil;
    
    /** starting of position for buffer playback */
    private var _startingFrame: AVAudioFramePosition! = nil;
    
    /** ending position for buffer playback */
    private var _endingFrame: AVAudioFramePosition! = nil;
    
    /** fade time in miliseconds */
    private let _fadeTime = 10.0;
    
    /** based upon the sample rate of the loaded audio file */
    private let _fadeIncrement = -1;
    
    //  TODO: we are assuming that 10ms will consist of 441 samples IF the sample rate is 44100
    /** = (file's sample frequency * _fadeTime) / 1000 ms */
    private var _fadeSampleCount = -1.0;
    
    //  TODO: 441 positions???
    private var _fadeInArray: [Float] = [];
    private var _fadeOutArray: [Float] = [];
    
    /** the frame number where the fade out envelope begins */
    private var _fadeOutStartPosition: Int = -1;
    
    /** number of files in the array */
    private var _playerNodeArrayCount: Int = 5;
    var playerNodeArrayCount: Int{    get{    return _playerNodeArrayCount; }   }
    
    //  TODO:   can we go down to one playerNode????
    /** iterating through an array of player nodes per start command has a number of musical adavantages */
    private var _playerNodeArray: [AVAudioPlayerNode?]! = nil;
    var playerNodeArray: [AVAudioPlayerNode?]
    {
        get{    return _playerNodeArray;    }
        set{    _playerNodeArray = newValue; }
    }
    
    private var _varispeedNodeArray: [AVAudioUnitVarispeed?]! = nil;
    var varispeedNodeArray: [AVAudioUnitVarispeed?]
    {
        get{    return _varispeedNodeArray;  }
        set{    _varispeedNodeArray = newValue; }
    }
    
    /** reflects whether this has a sound loaded */
    private var _isLoaded: Bool = false;
    var isLoaded: Bool
    {
        get{    return _isLoaded;   }
        set{    _isLoaded = newValue;   }
    }
    
    /** index of player node to play in array */
    private var _currentPlayIndex: Int = 0;
    var currentPlayIndex: Int{  get{    return _currentPlayIndex;    }   }
    
    /** where the loaded sound starts playing in frame number index.
        Public setter also sets _playFrameCount */
    private var _startPoint: Float! = nil;
    var startPoint: Float!
    {
        get{    return _startPoint;  }
        set
        {
            _startPoint = Float(newValue) * Float(_file.fileFormat.sampleRate);
            if(_endPoint == nil || _startPoint == nil){ _playFrameCount = AVAudioFrameCount(0); }
            else{   _playFrameCount = AVAudioFrameCount(_endPoint - _startPoint);   }
            
            _startingFrame = AVAudioFramePosition(_startPoint);
            
            //_opQueue.addOperation
            //{
                self.updateBuffer();
            //}
        }
    }
    
    /** where the loaded sound stops playing in frame number index.
        Public setter also sets _playFrameCount */
    private var _endPoint: Float! = nil;
    var endPoint: Float!
    {
        get{    return _endPoint;  }
        set
        {
            _endPoint = Float(newValue) * Float(_file.fileFormat.sampleRate);
            if(_endPoint == nil || _startPoint == nil){ _playFrameCount = AVAudioFrameCount(0); }
            else{   _playFrameCount = AVAudioFrameCount(_endPoint - _startPoint);   }
        
            _endingFrame = AVAudioFramePosition(_endPoint);
            //_opQueue.addOperation
            //{
                self.updateBuffer();
            //}
        }
    }
    
    /** the number of frames to play,
        calculated as endPoint - startPoint whenever either the start and end point members are set */
    private var _playFrameCount: AVAudioFrameCount = AVAudioFrameCount();
    
    /** if this is set to false,
     Play Through trigger mode is selected.
     Start/Stop trigger mode means the sound stops as soon as touch up occurs
     Play Through tirgger mode means touch up does not stop the sound from playing,
     the sound sill stop playing when it reaches the end of the file or the end point,
     whichever happens first */
    private var _startStopTriggerMode: Bool = true;
    var startStopTriggerMode: Bool
    {
        get{    return _startStopTriggerMode;   }
        set{    _startStopTriggerMode = newValue;   }
    }
    
    // TODO: setter for public member here probably needs some sort of conversion....
    /** the rate at which the sound will playback,
        effectivly affecting the sound's pitch */
    private var _rate: Float! = nil;
    var rate: Float
    {
        get{    return _rate;   }
        set{    _rate = newValue;   }
    }
    
    //  TODO: this only makes sense if we have the host written.
    // TODO: we need to enforce a strict range here
    /** right to left position of the sound in the stereo field */
    private var _pan: Float! = 0;
    var pan: Float
    {
        get{    return _pan;    }
        set{    _pan = newValue;    }
    }
    
    //  TODO: implement this at some point
    /** determines whether the sound will be played in mono or stereo mode */
    private var _stereo: Bool = true;
    var stereo: Bool
    {
        get{    return _stereo; }
        set{    _stereo = newValue; }
    }
    
    //  TODO: implement this at some point
    /** filter will have two modes,
            low pass and high pass */
    private var _filterLP: Bool = true;
    var filterLP: Bool
    {
        get{    return _filterLP;   }
        set{    _filterLP = newValue;   }
    }
    
    //  TODO: implement this at some point
    private var _filterFrequency: Float! = nil;
    var filterFrequency: Float
    {
        get{    return _filterFrequency;    }
        set{    _filterFrequency = newValue;    }
    }
    
    //  TODO: implement this at some point
    private var _filterResonance: Float! = nil;
    var filterResonance: Float
    {
        get{    return _filterResonance;    }
        set{    _filterResonance = newValue;    }
    }
    
    //  TODO: implement this at some point
    /** whether or not the sound will loop */
    private var _looping: Bool = false;
    var looping: Bool
    {
        get{    return _looping;   }
        set{    _looping = newValue;   }
    }
    
    //  TODO: implement this at some point
    /** determines looping  behavior of sound */
    private var _loopMode: Int = 0;
    var loopMode: Int
    {
        get{    return _loopMode;   }
        set{    _loopMode = newValue;   }
    }
    
    /** play signal to send to the host if the song is connected */
    private var _playSignalData: Data! = nil;
    var playSignalData: Data{   get{    return _playSignalData; }   }
    
    /** stop signal to send to the host if the song is connected */
    private var _stopSignalData: Data! = nil;
    var stopSignalData: Data{   get{    return _stopSignalData; }   }
    
    init(file: URL, bankNumber: Int, padNumber: Int, hardwareOutputs: Int)
    {
        assert(hardwareOutputs != -1)
        _hardwareOutputs = hardwareOutputs;
        
        do
        {
            // use public setter to set up start and end frame counts and positions
            self.file = try AVAudioFile(forReading: file);
        }
        catch
        {
            print("PadModel for bankNumber: " + bankNumber.description + " and padNumber: " + padNumber.description + " could not intialize audio file: " + file.lastPathComponent);
            print(error.localizedDescription);
        }
        
        _bankNumber = bankNumber;
        _padNumber = padNumber;
        
        _fileName = file.lastPathComponent;
        
        _playerNodeArray = [AVAudioPlayerNode?](repeating: nil, count: _playerNodeArrayCount);
        _varispeedNodeArray = [AVAudioUnitVarispeed?](repeating: nil, count: _playerNodeArrayCount);
        
        setNodeArray(audiofile: _file);
        
        let playSignalString = "play: " + bankNumber.description + " " + padNumber.description;
        _playSignalData = playSignalString.data(using: .ascii);
        
        let stopSignalString = "stop: " + bankNumber.description + " " + padNumber.description;
        _stopSignalData = stopSignalString.data(using: .ascii);
    }
    
    /** init all player and varispeed nodes in their respective arrays */
    func setNodeArray(audiofile: AVAudioFile)
    {
        for i in 0 ..< _playerNodeArrayCount
        {
            if(_playerNodeArray[i] == nil)
            {
                var tempNode: AVAudioPlayerNode! = nil;
                tempNode = AVAudioPlayerNode();
                _playerNodeArray[i] = tempNode;
            }
            
            if(_varispeedNodeArray[i] == nil)
            {
                var tempNode: AVAudioUnitVarispeed! = nil;
                tempNode = AVAudioUnitVarispeed();
                _varispeedNodeArray[i] = tempNode;
            }
        }
        
        _isLoaded = true;
    }
    
    /** play the loaded sound from its start point to its end point */
    func play()
    {
        //  having both start point == 0 and end point == nil here should mean
        //          that we are trying to preview the sound immediatley after choosing it in the FileSelectorVC
        if(_startPoint == 0 && _endPoint == nil) // TODO: <- don't change this to OR !!!!
        {
            // use the public setter in order to set _playFrameCount
            endPoint = Float(Double(_file.length)/_file.fileFormat.sampleRate);
        }
        
        // if current triggerMode is  play through,
        // stop the previous player node in the playerNode array from playing
        if(!_startStopTriggerMode)
        {
            if(_currentPlayIndex == 0)
            {   if(_playerNodeArray[_playerNodeArray.count - 1]?.isPlaying)!{    _playerNodeArray[_playerNodeArray.count - 1]?.stop();   }  }
            else
            {   if(_playerNodeArray[_currentPlayIndex - 1]?.isPlaying)!{    _playerNodeArray[_currentPlayIndex - 1]?.stop();    }   }
        }
        
        /** BAND AID ALERT ***********************************
            THIS BAND AID MUST BE REMOVED ONCE WE FIGURE OUT WHY WE ARE GETTING VALUES OF ZERO FOR START AND END POINTS
                UNDER CERTAIN CIRCUMSTANCES 
                    THIS BAND AID PREVENTS A RUN TIME ERROR */
        if(_playFrameCount == 0)
        {
            _playFrameCount = 1;
            print("BAND AID PLAYFRAMECOUNT WAS SET TO 1 IN PAD MODEL'S PLAY()");
        }
        
        _playerNodeArray[_currentPlayIndex]?.scheduleBuffer(_fileBuffer, completionHandler: nil);
       //_playerNodeArray[_currentPlayIndex]?.scheduleSegment(_file, startingFrame: AVAudioFramePosition(_startPoint), frameCount: _playFrameCount, at: nil, completionHandler: nil);
    
        _playerNodeArray[_currentPlayIndex]?.play();
    }
    
    // TODO: some sort of fade handling will need to happen here.....
    func stop()
    {
        let renderTime = _playerNodeArray[_currentPlayIndex]?.lastRenderTime
        let stopTime = _playerNodeArray[_currentPlayIndex]?.playerTime(forNodeTime: renderTime!);
        let stopFrame = stopTime?.sampleTime;
        let releaseFadeStartPosition = AVAudioFramePosition(_fadeOutStartPosition)
        
        // TODO:    get the current playing node's play buffer play position
        //              this is giving the time as in what time it is,
        //                  not where the play head stopped.
        print("stopped @ time: " + stopTime!.sampleTime.description);
        //print("stopped @ time: " + (stopTime! / AVAudioTime(hostTime: UInt64(_file.fileFormat.sampleRate))).description);
        
        //  TEST: we need to do an ear test of Playthrough mode to see if it produces any clicks
        // only stop if trigger mode is start/stop;
        if(_startStopTriggerMode)
        {
            //playerNodeArray[_currentPlayIndex]?.stop();
            
            // if we've stopped before the start of the fade out region....
            if(stopFrame! < releaseFadeStartPosition)    //  <-- I don't like this init call here!!!
            {
                //  apply the release fade...
                applyReleaseFade(position: stopFrame!)
            }
        }
        
        _currentPlayIndex = _currentPlayIndex == (_playerNodeArrayCount - 1) ? 0 : _currentPlayIndex + 1;
    }
    
    //https://github.com/AudioKit/AudioKit/blob/master/AudioKit/Common/Nodes/Playback/Player/AKAudioPlayer.swift
    private func initBuffer()
    {
        _fileBuffer = nil;
        _totalFrameCount = _file.length
        _startingFrame = 0;
        _endingFrame = _totalFrameCount;
        
        if(_file.length > 0){   updateBuffer()  }
        else
        {   print("file loaded into bank " + _bankNumber.description + " pad " + _padNumber.description + " is empty."); }
    }
    
    //  TODO: it looks like this is getting called more times than it needs to.....
    //  https://github.com/AudioKit/AudioKit/blob/master/AudioKit/Common/Nodes/Playback/Player/AKAudioPlayer.swift
    private func updateBuffer()
    {
        let tempStartFrame = _startingFrame;
        let tempEndFrame = _endingFrame;

        // if the loaded file has more than 0 samples
        if(_file.length > 0)
          {
            _file.framePosition = Int64(tempStartFrame!);
            _playFrameCount = AVAudioFrameCount(tempEndFrame! - tempStartFrame!);

            //  **********  TODO: audioKitPlayerNode has totalFrameCount for second arg here,
            //                      seems reasonable to only alocate for the segment defined by start and end points....
            _fileBuffer = AVAudioPCMBuffer(pcmFormat: _file.processingFormat, frameCapacity: AVAudioFrameCount(_totalFrameCount));

            do{ try _file.read(into: _fileBuffer, frameCount: _playFrameCount);  }
            catch
            {
                print("updateBuffer() could not read data into buffer: " + error.localizedDescription)
                return
            }

            self.applyFadeToBuffer();
        }
        else{  print("updateBuffer in PadModle could not update with empty file.");    }
    }
    
    /** apply the fade in and out envelopes(based upon the upper quadrants of the unit circle) to the buffer
            this method does not account for a fade out envelope if the user releases a pad before the end of the file or the set endpoint.*/
    private func applyFadeToBuffer()
    {
        let tempFadeBuffer = AVAudioPCMBuffer(pcmFormat: _file.processingFormat, frameCapacity: _fileBuffer.frameCapacity);
        let tempLength: UInt32 = _fileBuffer!.frameLength;
        
        _fadeOutStartPosition = Int(Double(tempLength) - (_file.processingFormat.sampleRate * (_fadeTime/1000)));
        
        var scalar: Float = 0.0;
        var fadeOutIndex = 0;
        
        if(_fadeInArray.count == 0) {   initFadeArrays();   }
        
        // i is the index in the buffer
        for i in 0 ..< Int(tempLength)
        {
            // n is the channel
            for n in 0 ..< Int(_fileBuffer.format.channelCount)
            {
                // if we are in the fade in region
                if(i < Int(_fadeSampleCount))
                {
                    scalar = _fadeInArray[i];
                
                    let sample = _fileBuffer!.floatChannelData![n][i] * scalar
                    tempFadeBuffer?.floatChannelData![n][i] = sample;
                }
            /** DEBUG: figuring out that setting incorrect bounds in this if-else cost us about two days,
                        the problem was that once the file completed playing once,
                            we would only hear silence on any subsequent plays,
                                the pad, however, would still light up as if sound was coming out.
                        So the moral of the story is,
                            you can break a buffer if you're not carefull about writing to within its bounds...*/
                // else if we are not in either fade region
                else if(i >= Int(_fadeSampleCount) && i <= _fadeOutStartPosition)
                {
                    // just copy the buffer straight over
                    tempFadeBuffer?.floatChannelData![n][i] = _fileBuffer.floatChannelData![n][i]
                }
                // else if we are in the fade out region
                else
                {
                    scalar = _fadeOutArray[fadeOutIndex]
                    
                    if(n == _fileBuffer.format.channelCount - 1){   fadeOutIndex += 1;  }
                    
                    let sample = _fileBuffer!.floatChannelData![n][i] * scalar
                    tempFadeBuffer?.floatChannelData![n][i] = sample;
                }
            }
        }
        
        // set the member buffer now to be the faded one
        _fileBuffer = tempFadeBuffer;
        // update this
        _fileBuffer.frameLength = tempLength;
    }
    
    /** makes arrays of values corresponding to 10 ms.
            current implementation has fades modeled after the upper quadrants of the unit circle. */
    private func initFadeArrays()
    {
        var currentFadeInValue = (1/_fadeSampleCount) - 1;
        var currentFadeOutValue = 1/_fadeSampleCount;
        
        for _ in 0 ..< Int(_fadeSampleCount)
        {
            _fadeInArray.append(Float(sqrt(1 - pow(currentFadeInValue, 2))))
            _fadeOutArray.append(Float(sqrt(1 - pow(currentFadeOutValue, 2))))
            
            currentFadeInValue += 1/_fadeSampleCount;
            currentFadeOutValue += 1/_fadeSampleCount;
        }
        
        //  TODO: we'll need to do that swap that we did in the master sound mod.....
    }
    
    private func applyReleaseFade(position: AVAudioFramePosition)
    {
        //  the number of samples in the fade out buffer
        let releaseFadeFrameCount = AVAudioFrameCount(_fadeOutArray.count);
        //let releaseBuffer = AVAudioPCMBuffer(pcmFormat: _file.fileFormat, frameCapacity: _fileBuffer.frameCapacity);
        let releaseBuffer = AVAudioPCMBuffer(pcmFormat: _file.processingFormat, frameCapacity: releaseFadeFrameCount);
        let fadeOutTerminus = Int(position + Int64(releaseFadeFrameCount));
        
        _file.framePosition = position;
        
        var fadeOutIndex = 0;
        
        //do{ try _file.read(into: releaseBuffer!, frameCount: AVAudioFrameCount(_totalFrameCount));  }
        do{ try _file.read(into: releaseBuffer!, frameCount: releaseFadeFrameCount);  }
        catch
        {
            print("applyReleaseFade() could not read data into buffer: " + error.localizedDescription);
            return;
        }
        
        for i in Int(position) ..< fadeOutTerminus
        {
            for n in 0 ..< Int(_fileBuffer.format.channelCount)
            {
                let scalar = _fadeOutArray[fadeOutIndex]
                
                if(n == _fileBuffer.format.channelCount - 1){   fadeOutIndex += 1;  }
                
                let sample = _fileBuffer!.floatChannelData![n][i] * scalar
                releaseBuffer?.floatChannelData![n][i] = sample;
            }
        }
        
        // stop the currently playing node
        _playerNodeArray[_currentPlayIndex]?.stop();
        
        // schedule the fade buffer
        _playerNodeArray[(_currentPlayIndex + 1) % _playerNodeArray.count]?.scheduleBuffer(releaseBuffer!, completionHandler: nil);
        
        // increment current play index
        _currentPlayIndex = _currentPlayIndex == (_playerNodeArrayCount - 1) ? 0 : _currentPlayIndex + 1;
        // play release fade buffer
        _playerNodeArray[_currentPlayIndex]?.play();
    }
}
