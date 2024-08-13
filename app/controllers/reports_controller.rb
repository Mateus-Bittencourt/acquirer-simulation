class ReportsController < ApplicationController
  def index
    report = {
      frauds_prevented: frauds_prevented,
      frauds_identified: frauds_identified,
      antifraud_system_failures: antifraud_system_failures,
      frauds_mal_identified: frauds_mal_identified
    }

    render json: report, status: :ok
  end

  private

  def frauds_prevented
    Transaction.where(has_cbk: true)
               .where(recommendation: 'deny')
               .count
  end

  def frauds_identified
    Transaction.where(has_cbk: true)
               .where(suspected_fraud: true)
               .count
  end

  def antifraud_system_failures
    Transaction.where(has_cbk: false)
               .where(recommendation: 'approve')
               .count
  end

  def frauds_mal_identified
    Transaction.where(has_cbk: false)
               .where(suspected_fraud: true)
               .count
  end
end
