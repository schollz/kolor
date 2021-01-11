json = require "json"
print("hi")

Account = {}
Account.__index = Account

function Account:create(balance)
   local acnt = {}             -- our new object
   setmetatable(acnt,Account)  -- make Account handle lookup
   acnt.balance = balance      -- initialize our object
   -- acnt.something = {somethingelse="hi"}
   -- acnt.b = {}
   -- acnt.b[1]={v=1,d=2}
   local data = json.decode('{"b":[{"d":2,"v":1}],"balance":700,"something":{"somethingelse":"hello"}}')
   for k,v in pairs(data) do 
   	acnt[k] = v
   end
   return acnt
end

function Account:withdraw(amount)
   self.balance = self.balance - amount
end

-- create and use an Account
acc = Account:create(1000)
acc:withdraw(100)
print(json.encode(acc))