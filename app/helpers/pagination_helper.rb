# paginator_helper.rb - Action Pack pagination helper
# Sam Stephenson <sstephenson at gmail dot com>
# http://actionpack.rubyonrails.org/show/PaginationHelper

module PaginationHelper
class Paginator
  include Enumerable

  # Creates a new Paginator on the given +controller+ for a set of
  # items of size +item_count+ and having +items_per_page+ items per
  # page. Raises ArgumentError if items_per_page is out of bounds
  # (i.e., less than or equal to zero).
  def initialize(controller, item_count, items_per_page, current_page=1)
    raise ArgumentError if items_per_page <= 0
    @controller = controller
    @item_count = item_count || 0
    @items_per_page = items_per_page
    self.current_page = current_page
  end
  attr_reader :controller, :item_count, :items_per_page

  # Sets the current page number of this paginator. If +page+ is a
  # Page object, its +number+ attribute is used as the value; if the
  # page does not belong to this Paginator, an ArgumentError is
  # raised.
  def current_page=(page)
    if page.is_a? Page
      raise ArgumentError unless page.paginator == self
    end
    page = page.to_i
    @current_page = has_page_number?(page) ? page : 1
  end

  # Returns a Page object representing this paginator's current page.
  def current_page
    self[@current_page]
  end
  alias current :current_page

  # Returns a new Page representing the first page in this paginator.
  def first_page
    self[1]
  end
  alias first :first_page

  # Returns a new Page representing the last page in this paginator.
  def last_page
    self[page_count] 
  end
  alias last :last_page

  # Returns the number of pages in this paginator.
  def page_count
    return 1 if @item_count.zero?
    (@item_count / @items_per_page.to_f).ceil
  end
  alias length :page_count      # makes Paginator more array-like

  # Returns true if this paginator contains the page of index
  # +number+.
  def has_page_number?(number)
    return false unless number.is_a? Fixnum
    number >= 1 and number <= page_count
  end

  # Returns a new Page representing the page with the given index
  # +number+.
  def [](number)
    Page.new(self, number)
  end

  # Successively yields all the paginator's pages to the given block.
  def each(&block)
    page_count.times do |n|
      yield self[n+1]
    end
  end

  # Builds a basic window of links, always showing the first and last page.
  def window_links( view, size = 2, link_current = false, link_opts = {} )
    window_pages = current.window( size ).pages
    return if window_pages.length <= 1 and not link_current
    html = ''
    unless window_pages[0].first?
      html << view.link_to( first.number, first.to_link.merge( link_opts ) )
      html << " ... " if window_pages[0].number - first.number > 1
    end
    for page in window_pages
      if current == page and not link_current
        html << page.number.to_s
      else
        html << view.link_to( page.number, page.to_link.merge( link_opts ) )
      end
      html << " "
    end
    unless window_pages.last.last?
      html << " ... " if last.number - window_pages[-1].number > 1
      html << view.link_to( last.number, last.to_link.merge( link_opts ) )
    end
    html
  end

  # A class representing a single page in a paginator.
  class Page
    include Comparable

    # Creates a new Page for the given +paginator+ with the index
    # +number+.  If +number+ is not in the range of valid page numbers
    # or is not a number at all, it defaults to 1.
    def initialize(paginator, number)
      @paginator = paginator
      @number = number.to_i
      @number = 1 unless @paginator.has_page_number? @number
    end
    attr_reader :paginator, :number
    alias to_i :number

    # Compares two Page objects and returns true when they represent
    # the same page (i.e., their paginators are the same and they have
    # the same page number).
    def ==(page)
      @paginator == page.paginator and 
        @number == page.number
    end

    # Compares two Page objects and returns -1 if the left-hand page
    # comes before the right-hand page, 0 if the pages are equal,
    # and 1 if the left-hand page comes after the right-hand page.
    # Raises ArgumentError if the pages do not belong to the same
    # Paginator object.
    def <=>(page)
      raise ArgumentError unless @paginator == page.paginator
      @number <=> page.number
    end

    # Returns the item offset for the first item in this page.
    def offset
      @paginator.items_per_page * (@number - 1)
    end

    # The number of the first item displayed.
    def first_item
      offset + 1
    end

    # The number of the last item displayed.
    def last_item
      [@paginator.items_per_page * @number, @paginator.item_count].min
    end
   
    # Returns true if this page is the first page in the paginator.
    def first?
      self == @paginator.first
    end

    # Returns true if this page is the last page in the paginator.
    def last?
      self == @paginator.last
    end

    # Returns a new Page object representing the page just before this
    # page, or nil if this is the first page.
    def previous
      if first? then nil else Page.new(@paginator, @number - 1) end
    end

    # Returns a new Page object representing the page just after this
    # page, or nil if this is the last page.
    def next
      if last? then nil else Page.new(@paginator, @number + 1) end
    end

    # Returns a new Window object for this page with the specified 
    # +padding+.
    def window(padding=2)
      Window.new(self, padding)
    end

    # Returns a hash appropriate for using with to_link or url_for.
    def to_link
      {:params => {'page' => @number.to_s}}
    end

    # Returns the SQL "LIMIT ... OFFSET" clause for this page.
    def to_sql
      "#{@paginator.items_per_page} OFFSET #{offset}"
    end
  end

  # A class for representing ranges around a given page. Thanks to
  # Marcel Molina Jr (noradio on Freenode) for the great idea and
  # the original implementation!
  class Window
    # Creates a new Window object for the given +page+ with the
    # specified +padding+.
    def initialize(page, padding=2)
      @paginator = page.paginator
      @page = page
      self.padding = padding
    end
    attr_reader :paginator, :page

    # Sets the window's padding (the number of pages on either side).
    def padding=(padding)
      @padding = padding < 0 ? 0 : padding
      # Find the beginning and end pages of the window
      @first = @paginator.has_page_number?(@page.number - @padding) ?
        @paginator[@page.number - @padding] : @paginator.first
      @last =  @paginator.has_page_number?(@page.number + @padding) ?
        @paginator[@page.number + @padding] : @paginator.last
    end
    attr_reader :padding, :first, :last

    # Returns an array of Page objects in the current window.
    def pages
      (@first.number..@last.number).to_a.map {|n| @paginator[n]}
    end
    alias to_a :pages
  end

end
end
