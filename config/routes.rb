Rails.application.routes.draw do
  post 'upload_csv', to: 'csv_processor#upload'
  post 'report_fraud', to: 'acquirer_reports#report_fraud'
  get 'report', to: 'reports#index'
end
