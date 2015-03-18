require "oil"
oil.main(function()
	local orb = oil.init()
	orb:loadidlfile("philo.idl")
	
	ForkHome        = orb:newproxy(oil.readfrom("fork.ior"))
	PhilosopherHome = orb:newproxy(oil.readfrom("philo.ior"))
	ObserverHome    = orb:newproxy(oil.readfrom("observer.ior"))
	
	Observer = ObserverHome:create()
	
	Fork = {
		ForkHome:create(),
		ForkHome:create(),
		ForkHome:create(),
	}
	
	Philo = {
		PhilosopherHome:create("Socrates"),
		PhilosopherHome:create("Plato"),
		PhilosopherHome:create("Aristoteles"),
	}
	
	Philo[1]:_set_info(Observer)
	Philo[1]:_set_left_fork (Fork[1])
	Philo[1]:_set_right_fork(Fork[2])
	
	Philo[2]:_set_info(Observer)
	Philo[2]:_set_left_fork (Fork[2])
	Philo[2]:_set_right_fork(Fork[3])
	
	Philo[3]:_set_info(Observer)
	Philo[3]:_set_left_fork (Fork[3])
	Philo[3]:_set_right_fork(Fork[1])
	
	Philo[1]:start()
	Philo[2]:start()
	Philo[3]:start()
end)
