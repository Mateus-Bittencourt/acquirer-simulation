class AcquirerReportsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def report_fraud
    data = JSON.parse(request.body.read)

    transaction_id = data['transaction_id']
    suspected_fraud = data['suspected_fraud']

    transaction = Transaction.find_by(transaction_id: transaction_id)

    if transaction
      transaction.update!(suspected_fraud: suspected_fraud)
      render json: { message: 'Transaction updated successfully' }, status: :ok
    else
      render json: { error: 'Transaction not found' }, status: :not_found
    end
  rescue StandardError => e
    Rails.logger.error("Error updating transaction: #{e.message}")
    render json: { error: 'Internal server error' }, status: :internal_server_error
  end
end
