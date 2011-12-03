package
{
	import com.newgrounds.*;
	import com.newgrounds.components.*;
	
	import net.flashpunk.*;
	
	public class Scores
	{
		public static function get hasScoreboard ():Boolean
		{
			return (API.sessionId && API.sessionId != "0");
		}
		
		public static function get canSubmit ():Boolean
		{
			return (API.sessionId && API.sessionId != "0");
		}
		
		public static function submitScore ():void
		{
			API.postScore("Total_score", Main.so.data.totalScore || 0);
		}
		
		public static function showScores ():void
		{
			var scoreBrowser:ScoreBrowser = new ScoreBrowser();
			scoreBrowser.scoreBoardName = "Total_score";
			scoreBrowser.period = ScoreBoard.ALL_TIME;
			scoreBrowser.loadScores();
			FP.engine.addChild(scoreBrowser);
		}
	}
}

