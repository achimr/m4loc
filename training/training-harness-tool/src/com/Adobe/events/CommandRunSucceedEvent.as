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


package com.Adobe.events
{
	import flash.events.Event;
	
	public class CommandRunSucceedEvent extends Event
	{
		public static var Command_Run_Succeed:String = "commandRunSucceed"; 
		
		public var command:String = new String;
		
		public function CommandRunSucceedEvent(type:String, command:String="", bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.command = command;
		}
		
		override public function clone():Event
		{
			var event:CommandRunSucceedEvent = new CommandRunSucceedEvent(Command_Run_Succeed);
			return event;
		}
//		private var _command:String = new String();
//		
//		public function set command(value:String):void
//		{
//			_command = value;
//			
//			dispatchEvent(new Event("commandChanged"));
//		}
//		
//		[Bindable(event="commandChanged")]
//		public function get command():String
//		{
//			return _command;
//		}
		
	}
}