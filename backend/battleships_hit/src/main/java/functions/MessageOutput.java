package functions;

public class MessageOutput
{
  private String _by = null;
  private String _against = null;
  private String _gameID = null;
  private String _matchID = null;
  private String _origin = null;
  private String _type = null;
  private long _timestamp = 0;
  private boolean _human = false;
  
  // Setters
  public void setBy( String by ) { _by = by; }
  public void setAgainst( String against ) { _against = against; }
  public void setGameID( String gameID ) { _gameID = gameID; }
  public void setMatchID( String matchID ) { _matchID = matchID; }
  public void setOrigin( String origin ) { _origin = origin; }
  public void setType( String type ) { _type = type; }
  public void setTimestamp( long timestamp ) { _timestamp = timestamp; }
  public void setHuman( boolean human ) { _human = huamn; }
  
  // Accessors
  public String getBy() { return _by; }
  public String getAgainst() { return _against; }
  public String getGameID() { return _gameID; }
  public String getMatchID() { return _matchID; }
  public String getOrigin() { return _origin; }
  public String getType() { return _type; }
  public long getTimestamp() { return _timestamp; }
  public boolean getHuman() { return _human; }
}