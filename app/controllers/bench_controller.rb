class BenchController < ApplicationController
  before_filter :login_required
  permit 'site_admin'
  
  def index
    @page_title = 'Admin : Benchmarking for '
    redirect_to :action => :list
  end
  
  def list
    @page_title = 'Admin : Benchmarking for '
    @path = File.expand_path(RAILS_ROOT + "/public/system/data")
    @production_log_graph = open_flash_chart_object('100%','100%', '/bench/production_log_graph', false, '/', true) 
    @pl_analyze_graph = open_flash_chart_object('100%','100%', '/bench/pl_analyze_graph', false, '/', true) 
    @zero_requests_graph = open_flash_chart_object('100%','100%', '/bench/zero_requests_graph', false, '/', true) 
  end
  
  def view
    @page_title = "Admin : BenchGraphs on "
    @graph = open_flash_chart_object('100%','100%', '/bench/' + params[:chart], false, '/', true) 
  end
  
  def production_log_graph
    g = Graph.new
    g.title( 'Production Log (combined)', '{color: #7E97A6; font-size: 20; text-align: center}' )
    
    @path = File.expand_path(RAILS_ROOT + "/public/system/data")
    completed_log = Dir[@path + "/completed-total*"].sort.reverse.first
    completed_rendering_log = Dir[@path + "/completed-rendering*"].sort.reverse.first
    completed_database_log = Dir[@path + "/completed-database*"].sort.reverse.first

    completed_log_data = File.readlines(completed_log)
    completed_rendering_data = File.readlines(completed_rendering_log)
    completed_database_data = File.readlines(completed_database_log)
    
    data_1 = LineHollow.new(2,5,'#CC3399')
    data_1.key("Total",10)
    
    data_2 = LineHollow.new(2,5,'#9933CC')
    data_2.key("Rendering",10)
    
    data_3 = LineHollow.new(2,5,'#80a033')
    data_3.key("Database",10)
    
    completed_log_data.collect{ |line|
      url = line.split('|')[-1].split(' ')[2].gsub('?', '?<br>').gsub('&', '&<br>').gsub('[', '').gsub(']','')
      data_1.add_data_tip( line.split('|')[0].split('|')[0].split(':')[3].split(' ')[2].to_i, url )
    }
    
    completed_rendering_data.collect{ |line|
      url = line.split('|')[-1].split(' ')[2].gsub('?', '?<br>').gsub('&', '&<br>').gsub('[', '').gsub(']','')
      data_2.add_data_tip( line.split('|')[0].split('|')[0].split(':')[3].split(' ')[2].to_i, url )
    }
    
    completed_database_data.collect{ |line|
      url = line.split('|')[-1].split(' ')[2].gsub('?', '?<br>').gsub('&', '&<br>').gsub('[', '').gsub(']','')
      data_3.add_data_tip( line.split('|')[0].split('|')[0].split(':')[3].split(' ')[2].to_i, url )
    }
    
    g.data_sets << data_1
    g.data_sets << data_2
    g.data_sets << data_3
    
    g.set_tool_tip('#x_label# [#val#]<br>#tip#')
    
    g.set_y_max(20)
    
    g.set_x_legend( 'Date', 12, '#164166' )
    g.set_y_legend( 'Response time (secs)', 12, '#164166' )
    
    dates = completed_log_data.collect{ |line| line.split(' ')[2..4].join(' ') }
    g.set_x_labels(dates)
    g.set_x_label_style(10, '#164166', 2, 3 )
    
    g.set_y_label_steps(10)
    
    render :text => g.render
  end
  
  def pl_analyze_graph
    g = Graph.new
    g.title( 'pl_analyze Log', '{color: #7E97A6; font-size: 20; text-align: center}' )
    
    @path = File.expand_path(RAILS_ROOT + "/public/system/data")
    log = Dir[@path + "/pl_analyze*"].sort.reverse.first
    
    raw_data = File.read(log)
    data = raw_data.split('------------------------------------------------------------------------')
    
    # Fragile, but now we have to hack the log files
    request_times = data[0].split("\n")
    top_requests = request_times[3..7]
    
    data_1 = LineHollow.new(2,5,'#CC3399')
    data_1.key("Request times",10)
    
    top_requests.collect{ |line|
      chunks = line.split(" ")
      tooltip = chunks[0] + "<br>Std Dev: " + chunks[3]
      data_1.add_data_tip(chunks[1], tooltip)
    }
    
    g.data_sets << data_1
    
    g.set_tool_tip('#x_label# [#val#]<br>#tip#')
    
    g.set_y_max(120000)
    
    g.set_x_legend( 'Standard deviation', 12, '#164166' )
    g.set_y_legend( 'Request count', 12, '#164166' )
    
    g.set_x_labels(top_requests.collect{ |r| r.split(" ")[3].to_f }.sort.uniq.reverse)
    g.set_x_label_style(10, '#164166', 2, 3 )
    
    g.set_y_label_steps(10)
    
    render :text => g.render
  end
  
  def zero_requests_graph
    g = Graph.new
    g.title( '0 reqs/second log', '{color: #7E97A6; font-size: 20; text-align: center}' )
    
    @path = File.expand_path(RAILS_ROOT + "/public/system/data")
    log = Dir[@path + "/zero_requests*"].sort.reverse.first
    
    slowest_requests = File.readlines(log)
    
    data_1 = LineHollow.new(2,5,'#CC3399')
    data_1.key("Slow requests",10)
    
    slowest_requests.collect{ |line|
      chunks = line.split(" ")
      time = chunks[0].gsub('[', '').gsub(']', '')
      rendering = chunks[14]
      queries = chunks[20]
      url = chunks[-1].gsub('?', '?<br>').gsub('&', '&<br>').gsub('[', '').gsub(']','')
      tooltip = time + "<br>Rendering time: " + rendering + "<br>Num. queries: " + queries + "<br>Url: " + url
      data_1.add_data_tip(time, tooltip)
    }
    
    g.data_sets << data_1
    
    g.set_tool_tip('#x_label# [#val#]<br>#tip#')
    
    g.set_y_max(15)
    
    g.set_x_legend( 'Date', 12, '#164166' )
    g.set_y_legend( 'Request time', 12, '#164166' )
    
    dates = slowest_requests.collect{ |req| req.split(" ")[2..4].join(" ").to_time.to_i }.sort
    g.set_x_labels(dates.collect{ |date| Time.at(date) })
    g.set_x_label_style(10, '#164166', 2, 3 )
    
    g.set_y_label_steps(10)
    
    render :text => g.render
  end
end