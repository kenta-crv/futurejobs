class CustomersController < ApplicationController
  before_action :authenticate_admin!

  def index
    last_call_customer_ids = nil
    @last_call_params = {}
    if params[:last_call] && !params[:last_call].values.all?(&:blank?)
      @last_call_params = params[:last_call]
      last_call = Call.joins_last_call
      last_call = last_call.where(statu: @last_call_params[:statu]) if !@last_call_params[:statu].blank?
      last_call = last_call.where("calls.time >= ?", @last_call_params[:time_from]) if !@last_call_params[:time_from].blank?
      last_call = last_call.where("calls.time <= ?", @last_call_params[:time_to]) if !@last_call_params[:time_to].blank?
      last_call = last_call.where("calls.created_at >= ?", @last_call_params[:created_at_from]) if !@last_call_params[:created_at_from].blank?
      last_call = last_call.where("calls.created_at <= ?", @last_call_params[:created_at_to]) if !@last_call_params[:created_at_to].blank?
      last_call_customer_ids = last_call.pluck(:customer_id)
    end
    @q = Customer.ransack(params[:q]) || Customer.ransack(params[:last_call])
    @customers = @q.result || @q.result.includes(:last_call)
    @customers = @customers.where( id: last_call_customer_ids )  if !last_call_customer_ids.nil?
    @customers = @customers.page(params[:page]).per(30)
    respond_to do |format|
     format.html
     format.csv{ send_data @customers.generate_csv, filename: "customers-#{Time.zone.now.strftime('%Y%m%d%S')}.csv" }
    end
    @all = @customers.all
  end

  def show
    last_call_customer_ids = nil
    @last_call_params = {}
    if params[:last_call] && !params[:last_call].values.all?(&:blank?)
      @last_call_params = params[:last_call]
      last_call = Call.joins_last_call
      last_call = last_call.where(statu: @last_call_params[:statu]) if !@last_call_params[:statu].blank?
      last_call = last_call.where("calls.time >= ?", @last_call_params[:time_from]) if !@last_call_params[:time_from].blank?
      last_call = last_call.where("calls.time <= ?", @last_call_params[:time_to]) if !@last_call_params[:time_to].blank?
      last_call = last_call.where("calls.created_at >= ?", @last_call_params[:created_at_from]) if !@last_call_params[:created_at_from].blank?
      last_call = last_call.where("calls.created_at <= ?", @last_call_params[:created_at_to]) if !@last_call_params[:created_at_to].blank?
      last_call_customer_ids = last_call.pluck(:customer_id)
    end
    @customer = Customer.find(params[:id])
    @q = Customer.ransack(params[:q]) || Customer.ransack(params[:last_call])
    @customers = @q.result || @q.result.includes(:last_call)
    @customers = @customers.where( id: last_call_customer_ids )  if !last_call_customer_ids.nil?
    @call = Call.new
    @prev_customer = @customers.where("customers.id < ?", @customer.id).last
    @next_customer = @customers.where("customers.id > ?", @customer.id).first
    @is_auto_call = (params[:is_auto_call] == 'true')
  end

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.new(customer_params)
     if @customer.save
       redirect_to customers_path
     else
       render 'new'
     end
  end

  def edit
    @customer = Customer.find(params[:id])
  end

  def update
    @customers = Customer&.where(worker_id: current_worker.id)
    @count_day = @customers.where('updated_at > ?', Time.current.beginning_of_day).where('updated_at < ?',Time.current.end_of_day).count
    @customer = Customer.find(params[:id])
      if @customer.update(customer_params)
        flash[:notice] = "??????????????????????????????1??????????????????????????????????????????#{30 - @count_day}????????????"
        redirect_to customer_path
      else
        render 'edit'
      end
  end

  def destroy
    @customer = Customer.find(params[:id])
    @customer.destroy
    redirect_to customers_path
  end

  def destroy_all
    checked_data = params[:deletes].keys #check????????????????????????
    if Customer.destroy(checked_data)
      redirect_to customers_path
    else
      render action: 'index'
    end
  end

  private
    def customer_params
      params.require(:customer).permit(
        :company, #?????????
        :name, #???????????????
        :tel, #????????????
        :mobile, #????????????
        :mail, #?????????????????????
        :postnumber, #????????????
        :address, #??????
        :url, #??????????????????
        :industry, #??????????????????
        :item, #????????????
        :price, #????????????
        :number, #??????
        :history, #????????????????????????
        :area, #????????????????????????
        :option, #???????????????
        :target, #?????????
        :next, #???????????????
        :content #??????????????????
       )
    end
end
