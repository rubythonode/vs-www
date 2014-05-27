class Stock < ActiveRecord::Base
  attr_protected
  belongs_to :issue, :counter_cache => true
  has_many :users, :through => :userStocks
  has_many :userStocks
  has_many :logStocks
  cattr_accessor :user_id
  scope :today, lambda{ where(["created_at = ?", Date.today])}

  def self.update_money(id)
    stock = Stock.find_by_id(id)
    stock.update_attribute(:money, (stock.money * UserStock.count_by_stock(id) / UserStock.count_by_issue(stock.issue.id)).ceil.to_i)
    stock.money
  end

  def user_stock_cnt
    user_stock = UserStock.find(:first, :conditions => ["stock_id = ? AND user_id = ?",id, Stock.user_id])
    if user_stock.nil? then 0 else user_stock.stock_amounts end
  end

  def last_week
    
  end

  def this_week
    this_week = LogStock.where("created_at BETWEEN CURDATE()-INTERVAL 1 WEEK AND CURDATE() + INTERVAL 1 DAY AND stock_id=#{id}")
      .select("stock_money, DATE_FORMAT(created_at, '%w') as day_of_week")
    day_of_week = ["0","1","2","3","4","5","6"].reject{|day| this_week.collect{|stock| stock.day_of_week}.include?(day)}
    day_of_week.each{|day|
      stock = Hash.new
      stock[:stock_money] = 0
      stock[:day_of_week] = day
      this_week.push(stock)
    }
    this_week.sort{|a,b| a[:day_of_week].to_i <=> b[:day_of_week].to_i}
  end

  def total
  end
end
