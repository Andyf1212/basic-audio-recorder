//
//  AudioFunctions.swift
//  basicRecorder
//
//  Created by Andy Freeman on 3/27/22.
//

import Foundation
import AVFoundation

let session = AVAudioSession.sharedInstance()
var recording: Bool = false
var recordPermission = false

// GLOBALS
var sampleRate: Double = 44_100
var buffSize: Double = 0.005
var preferredMicOrientation = AVAudioSession.Orientation.bottom
var preferredPolarPattern = AVAudioSession.PolarPattern.cardioid


// set up microphone configuration
func setupMicrophone() {
    // get available inputs
    guard let inputs = session.availableInputs else {return}
    
    // find available mic
    guard let builtInMic = inputs.first(where: {
        $0.portType == AVAudioSession.Port.builtInMic
    }) else {return}
    
    // Find the data source at the specified orientation
    guard let dataSource = builtInMic.dataSources?.first(where: {
        $0.orientation == preferredMicOrientation
    }) else {return}
    
    // set data source's polar pattern
    do {
        try dataSource.setPreferredPolarPattern(preferredPolarPattern)
    } catch let error as NSError {
        print("Error setting polar pattern: \(error.localizedDescription)")
    }
    
    // set data source as the input's preferred data source
    do {
        try builtInMic.setPreferredDataSource(dataSource)
    } catch let error as NSError {
        print("Error setting input's preferred data source: \(error.localizedDescription)")
    }
    
    // set the built in mic as the preferred input
    do {
        try session.setPreferredInput(builtInMic)
    } catch let error as NSError {
        print("Error setting built-in mic as preferred input: \(error.localizedDescription)")
    }
    
    // print active configuration
    session.currentRoute.inputs.forEach {portDesc in
        print("Port: \(portDesc.portType)")
        if let ds = portDesc.selectedDataSource {
            print("Name: \(ds.dataSourceName)")
            print("Polar Pattern: \(String(describing: ds.selectedPolarPattern))")
        }
    }
}

// set up session
func sessionStart() {
    // check for microphone permission
    switch session.recordPermission {
    case .granted:
        print("Permission granted")
        recordPermission = true
    case .denied:
        print("Permission denied")
        recordPermission = false
    case .undetermined:
        print("Requesting permission")
        AVAudioSession.sharedInstance().requestRecordPermission{granted in
            if granted {recordPermission = true}
            else {recordPermission = false}
        }
    default:
        print("Error checking microphone permission")
    }
    
    // session category and mode
    do {
        try session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.measurement, options: [])
    } catch let error as NSError {
        print("Error setting session category: \(error.localizedDescription)")
    }
    
    // session sample rate
    do {
        try session.setPreferredSampleRate(sampleRate)
    } catch let error as NSError {
        print("Error setting sample rate: \(error.localizedDescription)")
    }
    
    // session I/O buffer
    do {
        try session.setPreferredIOBufferDuration(buffSize)
    } catch let error as NSError {
        print("Error setting I/O Buffer: \(error.localizedDescription)")
    }
    
    // activate the session
    do {
        try session.setActive(true)
    } catch let error as NSError {
        print("Error activating session: \(error.localizedDescription)")
    }
    
}


func toggleRecording() {
    if recording {
        print("Stopping recording...")
        
        
        recording = false
    } else {
        print("Starting recording...")
        
        
        recording = true
    }
}
