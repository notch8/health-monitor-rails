HealthMonitor::Engine.routes.draw do
  controller :health do
    get :check
    get :fail
  end
end
