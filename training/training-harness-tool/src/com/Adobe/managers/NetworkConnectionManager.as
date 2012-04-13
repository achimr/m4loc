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


package com.Adobe.managers
{
	import com.Adobe.events.CommandRunSucceedEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	
	import mx.collections.XMLListCollection;
	import mx.controls.Alert;
	import mx.managers.CursorManager;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import org.osmf.events.TimeEvent;

	/** 
	 * An event indicating that the command has been sent to server and successfully run.  
	 * @eventType mx.events.Event.commandRunSucceed
	 */
	[Event(name="commandRunSucceed", type="flash.events.Event")]
	
	/** 
	 * An event indicating that the command has been sent to server but fails to run.  
	 * @eventType mx.events.Event.commandRunSucceed
	 */
	[Event(name="commandRunFail", type="flash.events.Event")]
	
	[Bindable]
	public class NetworkConnectionManager extends EventDispatcher
	{
		private static var instance : NetworkConnectionManager;

		public function NetworkConnectionManager()
		{
			if( instance != null )
			{
				throw new Error("Singleton!");
			}
			
			init();
		}
		
		public static function getInstance() : NetworkConnectionManager
		{
			if ( instance == null )
			{
				instance = new NetworkConnectionManager();
			}
			return instance;
		}
		
		public var output:String = "";
		
		private const portal_url:String = "http://10.162.147.105/moses/main.php";
		private var http:HTTPService = new HTTPService();
		
//		private const output_url:String = "http://10.162.146.105/moses/php/output.php";
//
//		private var urlReq:URLRequest = new URLRequest(output_url);
//		private var urlLoader:URLLoader = new URLLoader();
		
		private var timer:Timer = new Timer(1000);
		private var count:int = 0;
		
		private var logFile:String = new String();
		
		private function init():void
		{
			http.url = portal_url;
			http.method = "POST";
			http.resultFormat = "text";			
			http.addEventListener(ResultEvent.RESULT, ResultHandler);
			http.addEventListener(FaultEvent.FAULT, FaultHandler);
			timer.addEventListener(TimerEvent.TIMER, TimerHandler);
			
		}
		
		public function clearOutput():void
		{
			timer.stop();
//			urlLoader.close();
			output = "";
			count = 0;
		}
				
		public function sendCommand(command : String, parameters : Object = null):void
		{
			
			http.request["name"] = command;
			
			switch (command)
			{
				case "Train":
				case "Tune":
				case "Train+Tune":
					CursorManager.setBusyCursor();
					
					clearOutput();
					
					http.request["train_id"]          = parameters["train_id"];
					http.request["lm_factor"]         = parameters["lm_factor"];
					http.request["lm_order"]          = parameters["lm_order"];
					http.request["src_lang"]          = parameters["src_lang"];
					http.request["tar_lang"]          = parameters["tar_lang"];
					http.request["train_corpus_name"] = parameters["train_corpus_name"];
					http.request["tune_corpus_name"]  = parameters["tune_corpus_name"];
					http.request["alignment"]         = parameters["alignment"];
					http.request["reordering"]        = parameters["reordering"];
					http.request["irstlm"]            = parameters["irstlm"];
					http.request["kenlm"]             = parameters["kenlm"];
					
					break;
					
				case "getResult":
					http.request["log_file"]          = parameters["log_file"];
					break;
					
			}
			
			
//			urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, StatusChangeHandler);
//			urlLoader.addEventListener(Event.COMPLETE, CompleteHandler);
//			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, IOErrorHandler);
			
//			for (var item:String in http.request)
//			{
//				trace(item + " = " + http.request[item]);
//			}
						
			var call:AsyncToken = http.send();
			call.name = command;
		}
		
		private function TimerHandler(event:TimerEvent):void
		{

			var parameters:Object = new Object();
			
			parameters["log_file"] = logFile;
			
			sendCommand("getResult", parameters);
		}
		
//		private function CompleteHandler(event:Event):void
//		{
//			output = String(event.currentTarget.data);
//		}
//		
//		private function IOErrorHandler(event:IOErrorEvent):void
//		{
//			timer.stop();
//			urlLoader.close();
//			output += "IO Error";
//		}
		
		private function ResultHandler(event:ResultEvent):void
		{
			CursorManager.removeBusyCursor();
			
			switch(event.token.name)
			{
				case "Train":
				case "Tune":
				case "Train+Tune":
					
					logFile = event.token.result.toString();					
					dispatchEvent(new CommandRunSucceedEvent("commandRunSucceed", event.token.name));
					timer.start();
					break;
				
				case "getResult":
					
					output = event.token.result.toString();
					break;
			}
			
		}

		private function FaultHandler(event:FaultEvent):void
		{
			if ( event.token.name != "getResult" )
			{
				CursorManager.removeBusyCursor();
				var faultstring:String = event.fault.faultString;
				Alert.show(faultstring + "\nPlease check your network setting.");
			}
			
			trace(event.token.result);

		}
		
	}
}