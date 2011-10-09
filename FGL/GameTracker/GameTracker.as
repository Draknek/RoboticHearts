/* This code copyright 2010 by Lucrative Gaming, LLC.
   Author: Eric Heimburg
   Date: Feb 27, 2010
   Version: 1.1 - bufixes from alpha release; this is the first "BETA" version
*/

package FGL.GameTracker
{
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.net.NetConnection;
	import flash.net.Responder;
	import flash.utils.Timer;
	
	/** GameTracker
	 * An object to send gameplay information to FlashGameLicense's server
	 * for later analysis.
	 * To use: 
	 * 1. Create one global GameTracker object for use throughout the entire program.
	 *    Upon creation, the code will automatically peer into the
	 *    hosting webpage's JavaScript to get the needed connection info.
	 *    (If that JavaScript is missing, it will quietly turn itself off.
	 *    This way you never need to worry about it doing stuff while off of FGL.)
	 * 2. Add calls to this GameTracker object at various places in your game. You don't need
	 *    to worry about if the GameTracker is enabled or not, because if it's disabled, the calls
	 *    you make won't do anything.
	 * 		a. Call beginGame() when a game begins, and endGame() when a game ends
	 * 		b. Call beginLevel() when a level begins, and endLevel() when a level ends
	 * 		c. Call checkpoint() if you want to note that a user has gotten to a checkpoint in the 
	 * 			current level
	 * 		d. Call alert() to report something important, such as "Player beat the game!" or 
	 * 			"Player read the instructions!"
	 * 		e. Call customMsg() to create a custom message for other purposes. The name of your 
	 * 			custom message cannot be more than 20 characters long.
	 * 
	 *	  For each of these functions, you will need to pass in the score, the "game state", and a 
	 *    custom message if desired. There may be additional parameters, too, but those three will 
	 *    always show up.
	 * 
	 *    The score is just what it sounds like: the game's current score.
	 *    The "game state" is a string, up to 80 characters long, describing the overall state of the game.
	 *    This is just for your use and is entirely optional. Suggested uses include: 
	 * 			o Brief description of the player's power-ups
	 * 			o What branches of the story the player chose
	 * 			o How much money (or other "alternate scores") the player has
	 *    This is never used for anything by FGL, but will show up in the reports for your own use.
	 *    The message parameter is a string up to 255 characters long. This can be anything you want.
	 *    NOTE that this class sometimes generates messages on its own for events that it has to spontaneously
	 *    emit. Those messages always start with "AUTO:".
	 *    The message parameter is entirely optional. However, for alert() events, the message is the
	 *    whole point, so passing null for those is kind of useless.
	 * 
	 *    Catching errors: you can call addEventListener to listen to GAMETRACKER_SERVER_ERROR and
	 *    GAMETRACKER_CODING_ERROR events. This is especially useful during development and testing!
	 * 
	 *    Note: the game tracker's timer is only accurate to a single second. (Although if you have many
	 *    events during the same second, they will be stored in order.) Thus, it's not really designed to
	 *    record individual mouse clicks or other very low level detail. It's intended for use at a slightly
	 *    higher granularity. Please don't use custom messages to generate more than 20 or 30 events 
	 *    per minute.
	 * 
	 *    The system queues the events you request, and sends them to the server every 15 seconds.
	 *    The exception is the endGame() and alert() events, which are sent immediately.
	 *    Remember that a Flash game doesn't reliably know when it's terminating, so there may always
	 *    be lost events in the last few seconds of the player's session!
	 * 
	 *    A final note: FGL counts a "sessions" as one user playing a game nonstop for several minutes.
	 *    What this means is that if the user hits F5 to refresh the web page, or leaves and comes back
	 *    a minute later, FGL is likely to consider the return as part of the SAME session. This is very   
	 *    useful when analyzing how people are using your game. Just be aware of it when looking at the 
	 *    results.
	 * 
	 *    After you have implemented this API in your game, upload it to FGL. To test it, just view
	 *    your game. After you've played for a little bit (at least 15 seconds!), go to your game's Views
	 *    listing. Click the checkbox that shows owner-views. (By default, it doesn't list the times
	 *    that you play your own game, but in this case you want to know that.) You'll see a link called
	 *    "view session". Click this to view the session report, examine the data, and download it for
	 *    offline viewing.
	 */
	public class GameTracker extends EventDispatcher
	{
		// you can catch this to get information about errors. It sends a GameTrackerErrorEvent as its event type! That object's _msg param is an English error message
		// FIXME: should be exceptions?
		public static const GAMETRACKER_SERVER_ERROR:String = "gametracker_server_error";
		public static const GAMETRACKER_CODING_ERROR:String = "gametracker_coding_error";
		
		private static const TIMER_DELAY:int = 15000; // please do not go faster than this, FGL's server will asplode
		
		/**
		 * Creates a GameTracker(). 
		 * Uses JavaScript to initialize itself to FGL's current system parameters.
		 * If the game isn't running on FGL, GameTracker will automatically shut itself off.
		 * You can check to see if it's enabled by calling isEnabled(), but you don't
		 * normally need to care. You can just call the functions assuming it's enabled,
		 * and they'll just do nothing if it's disabled.
		 */
		public function GameTracker()
		{
			setGlobalConfig();
			if (_isEnabled)
			{
				_responder = new Responder(onSuccess, onNetworkingError);
				_conn = new NetConnection();
				//_conn.objectEncoding = ObjectEncoding.AMF0;
				_conn.connect(_hostUrl);
				
				_timer = new Timer(TIMER_DELAY);
				_timer.addEventListener("timer", onTimer);
				_timer.start();
				
				_sessionID = Math.floor((new Date().getTime() / 1000));
				
				addToMsgQueue("begin_app", null, 0, null, null);
			}
		}
		
		/**
		 * Indicates that the GameTracker is attempting to send messages to the server
		 * periodically. This does not connote success in actually doing so, however!
		 */
		public function isEnabled():Boolean
		{
			return _isEnabled;
		}
		
		/**
		 * Call at the beginning of the game.
		 */
		public function beginGame(currentScore:Number = 0, currentGameState:String = null, customMsg:String = null):void
		{
			if (_inGame)
			{
				endGame(currentScore, currentGameState, "AUTO:(this game automatically ended when new game was started)");
			}
			_currentGame++;
			_inGame = true;  
			addToMsgQueue("begin_game", null, currentScore, currentGameState, customMsg);
		}
		
		/**
		 * Call at the end of the game.
		 * If you fail to call endGame(), the GameTracker attempts to do so for you when you
		 * next call beginGame(), but this isn't as accurate as you doing it yourself.
		 */
		public function endGame(currentScore:Number = 0, currentGameState:String = null, customMsg:String = null):void
		{
			if (!_inGame)
			{
				dispatchEvent(new GameTrackerErrorEvent(GAMETRACKER_CODING_ERROR, "endGame() called before beginGame() was called!"));
			}
			else
			{
				if (_inLevel)
				{
					endLevel(currentScore, currentGameState, "AUTO:(this level automatically ended when game ended)");
				}
				addToMsgQueue("end_game", null, currentScore, currentGameState, customMsg);
				_inGame = false;
				submitMsgQueue(); // fast-track this message because user may be about to quit game!
			}
		}
		
		/**
		 * Call when a level begins. You must call this AFTER you'be called beginGame().
		 */
		public function beginLevel(newLevel:int, currentScore:Number = 0, currentGameState:String = null, customMsg:String = null):void
		{
			if (!_inGame)
			{
				dispatchEvent(new GameTrackerErrorEvent(GAMETRACKER_CODING_ERROR, "beginLevel() called before beginGame() was called!"));
			}
			else
			{
				if (_inLevel)
				{
					endLevel(currentScore, currentGameState, "AUTO:(this level automatically ended when new level was started)");
				}
				_currentLevel = newLevel;
				_inLevel = true;  
				addToMsgQueue("begin_level", null, currentScore, currentGameState, customMsg);
			}
		}
		
		/**
		 * Call when a level ends. You must call this AFTER you've called beginLevel().
		 * If you fail to call endLevel(), the GameTracker attempts to do so for you when you
		 * next call beginLevel(), but this isn't as accurate as you doing it yourself.
		 */
		public function endLevel(currentScore:Number = 0, currentGameState:String = null, customMsg:String = null):void
		{
			if (!_inLevel)
			{
				dispatchEvent(new GameTrackerErrorEvent(GAMETRACKER_CODING_ERROR, "endLevel() called before beginLevel() was called!"));
			}
			else
			{
				_inLevel = false;  
				addToMsgQueue("end_level", null, currentScore, currentGameState, customMsg);
			}
		}
		
		/**
		 * Call this to denote that the user has reached a checkpoint in the current level.
		 * The exact meaning of what a "checkpoint" is is up to you. Some games like to emit
		 * checkpoint messages every 5 seconds, just to keep track of the user's score. That's okay.
		 * Just don't emit them more than every few seconds! (For our server's sanity.)
		 * 
		 * You can only call checkpoint during a game (that is, after beginGame() has been called).
		 * It can be between levels, though, if you want. Although that's kinda weird.
		 */
		public function checkpoint(currentScore:Number = 0, currentGameState:String = null, customMsg:String = null):void
		{
			if (!_inGame)
			{
				dispatchEvent(new GameTrackerErrorEvent(GAMETRACKER_CODING_ERROR, "checkpoint() called before startGame() was called!"));
			}
			else
			{
				addToMsgQueue("checkpoint", null, currentScore, currentGameState, customMsg);
			}
		}

        /**
        * Call this to point out that something important has happened. You pretty much always want to 
        * provide a customMsg when calling alert(), to indicate what happened. Good example alerts are:
        * 	"The user beat the game!"
        * 	"The user clicked on the instructions link"
        * 	"The game hit a fatal exception!"
        * 	"The user found the secret level!"
        * 
        * Alerts are often very important to your analysis, so they are sent immediately to the server.
        * For this reason, please don't overuse alerts. If you want to send notices every few seconds, use
        * checkpoint() or customMsg().
        */  
		public function alert(currentScore:Number = 0, currentGameState:String = null, customMsg:String = null):void
		{
			addToMsgQueue("alert", null, currentScore, currentGameState, customMsg);
			submitMsgQueue(); // fast-track this message because we assume alerts are too important to lose! Please don't abuse this fast-queue feature
		}

        /**
        * Send a message meaning... whatever you want it to mean. The "msgType" parameter must not be more than
        * 20 characters long. Please don't send these more than say 20 or 30 times per average minute.
        * (For our server's sanity.)
        */
		public function customMsg(msgType:String, currentScore:Number = 0, currentGameState:String = null, customMsg:String = null):void
		{
			addToMsgQueue("custom", msgType, currentScore, currentGameState, customMsg);
		}
		
		protected function addToMsgQueue(action:String, subaction:String, 
										 score:Number, gamestate:String, custom_msg: String):void
		{
			if (_isEnabled)
			{
				var msg:Object = new Object();
				msg['action'] = action;
				msg['custom_action'] = subaction;
				msg['session_id'] = _sessionID;
				msg['game_idx'] = _currentGame;
				msg['level'] = _currentLevel;
				msg['score'] = score;
				msg['game_state'] = gamestate;
				msg['time'] = Math.floor((new Date().getTime() / 1000));
				msg['msg'] = custom_msg;
				_msg_queue.push(msg);
			}
		}

		protected function submitMsgQueue():void
		{
			if (_isEnabled && _msg_queue.length > 0)
			{
				var obj:Object = new Object();
				obj['actions'] = _msg_queue;
				obj['identifier'] = _passphrase;
				//_conn.call(_serviceName, _responder, _passphrase, obj);
				_conn.call(_serviceName, _responder, obj);
				_msg_queue = new Array();
			}
		}
		
		// the timer that reminds us to submit the message queue
		protected var _timer:Timer = null;
		
		// the current "indices" for things like game number
		protected var _currentGame:int = 0;
		protected var _currentLevel:int = 0;
		protected var _inGame:Boolean = false;
		protected var _inLevel:Boolean = false;
		
		// the queue of pending events that have not been sent to the server yet
		protected var _msg_queue:Array = new Array();

		// networking vars set up by constructor
		protected var _conn:NetConnection = null;
		protected var _responder:Responder = null;
		protected var _sessionID:uint;
		

		// vars set by setGlobalConfig()
		protected var _isEnabled:Boolean = false;
		protected var _serverVersionMajor:int = 0;
		protected var _serverVersionMinor:int = 0;
		protected var _hostUrl:String = '';
		protected var _serviceName:String = '';
		protected var _passphrase:String = '';
		
		protected function setGlobalConfig():void
		{
			// this function calls a JavaScript function on the hosting page
			// to retrieve a bunch of setting data.
			// If that function can't be called or doesn't exist, or if the 
			// function indicates that the major version isn't what was expected,
			// then it disables itself. 
			_isEnabled = false;
			_serverVersionMajor = 0;
			_serverVersionMinor = 0;
			_hostUrl = '';
			_serviceName = '';
			_passphrase = '';
			try 
			{
				if (ExternalInterface.available)
				{
					var ret:Array = ExternalInterface.call("get_gametracker_info");
					_serverVersionMajor = ret[0];
					_serverVersionMinor = ret[1];
					_hostUrl = ret[2];
					_serviceName = ret[3];
					_passphrase = ret[4];
					_isEnabled = (_serverVersionMajor == 1);
				}
			}
			catch (e:*)
			{
			}
		}	
		
		protected function onSuccess(evt:*):void
		{
			if (evt.toString() != "")
			{
				dispatchEvent(new GameTrackerErrorEvent(GAMETRACKER_SERVER_ERROR, evt.toString()));
			}
		}
		
		protected function onNetworkingError(evt:*):void
		{
			dispatchEvent(new GameTrackerErrorEvent(GAMETRACKER_SERVER_ERROR, "Networking error"));
		}
		
		protected function onTimer(evt:TimerEvent):void
		{
			submitMsgQueue();
		}
									 
	}
}
