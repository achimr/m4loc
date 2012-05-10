//////////////////////////////////////////////////////////////////////////////////////
//
//    Copyright 2012 Adobe Systems Incorporated
//
//    This file is part of TMX to Moses Corpus Tool.
// 
//    TMX to Moses Corpus Tool is free software: you can redistribute it and/or modify
//    it under the terms of the GNU Lesser General Public License as published by the 
//    Free Software Foundation, either version 3 of the License, or (at your option) 
//    any later version.
// 
//    TMX to Moses Corpus Tool is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
//    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for 
//    more details.
// 
//    You should have received a copy of the GNU Lesser General Public License along 
//    with TMX to Moses Corpus Tool.  If not, see <http://www.gnu.org/licenses/>.
//
//////////////////////////////////////////////////////////////////////////////////////


package com.Adobe.process
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	
	import mx.controls.Alert;
	import mx.controls.ProgressBar;
	import mx.core.FlexGlobals;
	import mx.managers.PopUpManager;
	
	public class ConversionProcess
	{
		public function ConversionProcess()
		{
			selfHeal();
		}
		
		private var process:NativeProcess = new NativeProcess();
		private var processStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
		private var progress_bar:ProgressBar = new ProgressBar();
		private var selfHealed:Boolean = false;
		private var scriptPortalPath:File = new File(File.applicationDirectory.resolvePath("scripts").nativePath);
				
		private function selfHeal():void
		{
			progress_bar.labelPlacement = "center";
			progress_bar.mode = "manual";
			progress_bar.minimum = 0;
			progress_bar.maximum = 100;
			
			if (NativeProcess.isSupported)
			{
				var file:File = new File("/bin/bash");
				
				processStartupInfo.executable = file;
				
//				processStartupInfo.workingDirectory = new File(File.userDirectory.nativePath);
				processStartupInfo.workingDirectory = scriptPortalPath;
				var args:Vector.<String> = new Vector.<String>();
				
				args.push("-s");
				
				processStartupInfo.arguments = args;
				
				process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, getError);
				process.addEventListener(ProgressEvent.STANDARD_INPUT_PROGRESS, sendInput);
				process.addEventListener(NativeProcessExitEvent.EXIT, onComplete);
				process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, getOutput);
				
				process.start(processStartupInfo);
				
				selfHealed = true;
				
				function getOutput(event:Event):void
				{
					progress_bar.label = process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable);
//					Alert.show(process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable));
				}
				
				function getError(event:Event):void
				{
					progress_bar.label = process.standardError.readUTFBytes(process.standardError.bytesAvailable);
//					Alert.show(process.standardError.readUTFBytes(process.standardError.bytesAvailable));
					
					var stateRep:RegExp = /\[ERROR/i;
					
					if ( stateRep.test(process.standardError.readUTFBytes(process.standardError.bytesAvailable)) )
					{
						Alert.show("Fatal Error! Conversion stopped!");
						
						PopUpManager.removePopUp(progress_bar);
						
						process.exit();
					}
				}
				
				function sendInput(event:Event):void
				{
					process.closeInput();
				}
				
				function onComplete(event:Event):void
				{
					PopUpManager.removePopUp(progress_bar);
					
					var stateRep:RegExp = /\[WARNING/i;
					
					if ( stateRep.test(process.standardError.readUTFBytes(process.standardError.bytesAvailable)) )
					{
						Alert.show("The process is done while some warnings were found. Please check in the log file.");
					}
					
					process.exit();
				}
			}
			else
			{
				trace("NativeProcess not supported.");
			}
			
		}
		
		public function start(configFile:File):void
		{
			PopUpManager.addPopUp(progress_bar, DisplayObject(FlexGlobals.topLevelApplication.appUI) as Sprite, true)
			
			PopUpManager.centerPopUp(progress_bar);
			
			if (selfHealed)
			{
				var portalScript:String = scriptPortalPath.resolvePath("convert.py").nativePath;
//				var command:String = "/usr/local/bin/python '" + portalScript + "' -f '" + configFile.nativePath + "'\n";
				var command:String = "python '" + portalScript + "' -f '" + configFile.nativePath + "'\n";
				
				process.standardInput.writeUTFBytes(command);
			}
			else
			{
				PopUpManager.removePopUp(progress_bar);
			}
		}
	}
}