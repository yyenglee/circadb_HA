ActionController::Routing::Routes.draw do |map|
  map.root :controller => "query", :action => "human", :format => 'html'
  map.mouse '/mouse', :controller => "query", :action => "mouse", :format => 'html'
  map.query '/mouse_query.:format', :controller => "query", :action => "mouse"
  map.human_query '/human_query.:format', :controller => "query", :action => "human"
  #map.table '/table.:format', :controller => "table", :action => "write" , :format => 'html'
  map.help '/help', :controller => "query", :action => "help", :format => 'html'
  map.about '/about', :controller => "query", :action => "about", :format => 'html'
  map.advanced_query_help "/help", :anchor => 'querying', :controller => "query", :action => "help", :format => 'html'
  map.select_more_than_one "/help", :anchor => 'faq', :controller => "query", :action => "help", :format => 'html'
  map.mouse_help "/help", :anchor => 'mouse', :controller => "query", :action => "help", :format => 'html'
  map.human_help "/help", :anchor => 'human', :controller => "query", :action => "help", :format => 'html'
end
