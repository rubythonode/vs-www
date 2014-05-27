class StocksController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_action :stock
  before_action :validate, :only => [:buy, :sell]
  def buy
    stock_id = buy_params[:id]
    issue_id = @stock.issue.id
    stock_amounts = buy_params[:stock_amounts].to_i
    case User.buy_status(@user_id, stock_id, stock_amounts)
    when Code::MSG[:not_enough_money]
      render :json => fail(Code::MSG[:not_enough_money]) and return
    when Code::MSG[:success]
      unless UserStock.get(@user_id, stock_id, issue_id).blank?
        user_stock = UserStock.find(:first, :conditions => ["user_id = ? and stock_id = ? and issue_id = ?",@user_id, stock_id, issue_id])
        if !UserStock.find_by_id(user_stock.id).increment!(:stock_amounts, stock_amounts) 
          render :json => fail(Code::MSG[:buy_transaction_fail]) and return
        end
      else
        user_stock = UserStock.create(:user_id => @user_id, :stock_id => stock_id, :issue_id => issue_id, :stock_amounts=> stock_amounts)
      end
      if User.buy_stocks(@user_id, @stock.money, stock_amounts) && stock_money = Stock.update_money(stock_id)
        insert_log(
          Code::BUY,
          stock_amounts, 
          stock_id, 
          issue_id, 
          User.user_money(@user_id),
          stock_money,
        )
        result = success(UserStock.find_by_id(user_stock.id).as_json(:include => [:user, :stock, :issue]))
        result[:body][:buy_stock_amounts] = stock_amounts
        result[:body][:stock_money] = stock_money 
        render :json => result and return
      else
        render :json => fail(Code::MSG[:buy_transaction_fail]) and return
      end
    end
  end

  def insert_log(stock_type, stock_amounts, stock_id, issue_id, user_money, stock_money)
    LogUserStock.insert_log({
      :stock_type => stock_type,
      :stock_amounts => stock_amounts,
      :user_id => @user_id,
      :stock_id => stock_id,
      :issue_id => issue_id,
      :user_money => user_money,
      :stock_money => stock_money
    })
  end

  def sell
    stock_id = buy_params[:id]
    issue_id = @stock.issue.id
    stock_amounts = buy_params[:stock_amounts].to_i
    case result = User.sell_status(@user_id, stock_id, stock_amounts)
    when Code::MSG[:success]
      user_stock = UserStock.find(:first, :conditions => ["user_id = ? and stock_id = ? and issue_id = ?",@user_id, stock_id, issue_id])
      if UserStock.sell_stocks(@user_id, stock_id, stock_amounts) && User.sell_stocks(@user_id, @stock.money, stock_amounts) && money = Stock.update_money(stock_id)
         insert_log(
           Code::SELL,
           stock_amounts, 
           stock_id, 
           issue_id, 
           User.user_money(@user_id),
           @stock.money
         )
         result = success(UserStock.find_by_id(user_stock.id).as_json(:include => [:user, :stock, :issue]))
         result[:body][:sell_stock_amounts] = stock_amounts
         result[:body][:stock_money] = money
         render :json => result and return
      end
    when Code::MSG[:user_has_no_stock]
      render :json => fail(result) and return
    when Code::MSG[:user_stock_lack]
      render :json => fail(result) and return
    end
  end

  def show
    result = Hash.new
    result[:last_week] = LogUserStock.get_last_week_stock_amounts(show_params[:id])
    result[:this_week] = LogUserStock.get_this_week_stock_amounts(show_params[:id])
    result[:total] = LogUserStock.total_stock_amounts(show_params[:id])
    render :json => success(result)
  end

  private
  def buy_params
    params.permit(:id, :acc_token, :stock_amounts)
  end
  
  def sell_params
    params.permit(:id, :acc_token, :stock_amounts)
  end

  def show_params
    params.permit(:id)
  end


  def stock
    @stock = Stock.find_by_id(params[:id])
    if @stock.nil?
      render :json => fail(Code::MSG[:buy_transaction_fail]) and return
    end
  end

  def validate
    if !params.has_key?(:stock_amounts) || params[:stock_amounts].to_i == 0
      render :json => fail(Code::MSG[:stock_amounts_is_invaild]) and return
    end
  end
end