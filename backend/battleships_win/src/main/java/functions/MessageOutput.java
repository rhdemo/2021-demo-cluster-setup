package functions;

public class MessageOutput
{
  private String _player = null;
  private String _match = null;
  private String _game = null;
  private long _timestamp = 0;
  private boolean _human = false;
  
  // Setters
  public void setPlayer( String player ) { _player = player; }
  public void setMatch( String match ) { _match = match; }
  public void setGame( String game ) { _game = game; }
  public void setTimestamp( long timestamp ) { _timestamp = timestamp; }
  public void setHuman( boolean human ) { _human = human; }

  // Accessors
  public long getTimestamp() { return _timestamp; }
  public String getPlayer() { return _player; }
  public String getMatch() { return _match; }
  public String getGame() { return _game; }
  public boolean getHuman() { return _human; }
}