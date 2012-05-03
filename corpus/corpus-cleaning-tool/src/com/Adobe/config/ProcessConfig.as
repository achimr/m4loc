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


package com.Adobe.config
{
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class ProcessConfig extends EventDispatcher
	{
		private static var _instance:ProcessConfig;
		public function ProcessConfig()
		{
			if(_instance != null){
				throw new Error("Singleton!");
			}
		}
		
		public static function getInstance():ProcessConfig{
			if (_instance == null){
				_instance = new ProcessConfig();
			}
			return _instance;
		}
		
		private var _prjName:String;
		
		public function set projectName(prjName:String):void
		{
			_prjName = prjName;
			dispatchEvent(new Event("projectNameChanged"));
		}
		
		[Bindable(event="projectNameChanged")]
		public function get projectName():String
		{
			return _prjName;
		}
	}
}