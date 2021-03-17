package functions;

// POJO for emitted cloud event for Match End
public class MessageOutput
{
  private String _game = null;
  private String _match = null;
  private String _winnerUsername = null;
  private String _loserUsername = null;
  private String _winnerUuid = null;
  private String _loserUuid = null;
  private boolean _winnerHuman = true;
  private boolean _loserHuman = true;
  
  // Setters
  public void setGame( String game ) { _game = game; }
  public void setMatch( String match ) { _match = match; }
  public void setWinnerUsername( String winnerUsername ) { _winnerUsername = winnerUsername; }
  public void setLoserUsername( String loserUsername ) { _loserUsername = loserUsername; }
  public void setWinnerUuid( String winnerUuid ) { _winnerUuid = winnerUuid; }
  public void setLoserUuid( String loserUuid ) { _loserUuid = loserUuid; }
  public void setWinnerHuman( boolean winnerHuman ) { _winnerHuman = winnerHuman; }
  public void setLoserHuman( boolean loserHuman ) { _loserHuman = loserHuman; }
  
  // Accessors
  public String getGame() { return _game; }
  public String getMatch() { return _match; }
  public String getWinnerUsername() { return _winnerUsername; }
  public String getLoserUsername() { return _loserUsername; }
  public String getWinnerUuid() { return _winnerUuid; }
  public String getLoserUuid() { return _loserUuid; }
  public boolean getWinnerHuman() { return _winnerHuman; }
  public boolean getLoserHuman() { return _loserHuman; }

}