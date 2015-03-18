require 'classlib'

class.Account()
function Account:__init(initial)
    self.balance = initial or 0
end
function Account:deposit(amount)
    self.balance = self.balance + amount
end
function Account:withdraw(amount)
    self.balance = self.balance - amount
end
function Account:getbalance()
    return self.balance 
end

class.NamedAccount(shared(Account))    -- shared Account base
function NamedAccount:__init(name, initial)
    self.Account:__init(initial)
    self.name = name or 'anonymous'
end

class.LimitedAccount(shared(Account))  -- shared Account base
function LimitedAccount:__init(limit, initial)
    self.Account:__init(initial)
    self.limit = limit or 0
end
function LimitedAccount:withdraw(amount)
    if self:getbalance() - amount < self.limit then
       error 'Limit exceeded'
    else
       self.Account:withdraw(amount)
    end
end

class.NamedLimitedAccount(NamedAccount, LimitedAccount)
function NamedLimitedAccount:__init(name, limit, initial)
    self.Account:__init(initial)
    self.NamedAccount:__init(name)
    self.LimitedAccount:__init(limit)
end
-- widthdraw() disambiguated to the limit-checking version
function NamedLimitedAccount:withdraw(amount)
    return self.LimitedAccount:withdraw(amount)
end

myNLAccount = NamedLimitedAccount('John', 0.00, 10.00)
myNLAccount:deposit(2.00)
print('balance now', myNLAccount:getbalance())   --> 12.00
myNLAccount:withdraw(1.00)
print('balance now', myNLAccount:getbalance())   --> 11.00
--myNLAccount:withdraw(15.00)                    --> error, limit exceeded
