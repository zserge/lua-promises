local tests_passed = 0
local tests_failed = 0
require('gambiarra')(function(e, test, msg)
	if e == 'pass' then
		print("[32m✔[0m "..test..': '..msg)
		tests_passed = tests_passed + 1
	elseif e == 'fail' then
		print("[31m✘[0m "..test..': '..msg)
		tests_failed = tests_failed + 1
	elseif e == 'except' then
		print("[31m✘[0m "..test..': '..msg)
		tests_failed = tests_failed + 1
	end
end)

local deferred = require('deferred')

test('A+ check api', function()
	local d = deferred.new()
	ok(type(d.resolve) == 'function', 'has resolve() method')
	ok(type(d.reject) == 'function', 'has reject() method')
	ok(type(d.next) == 'function', 'has thenable method')
end)

test('A+ 2.1.1.1 pending promise may transition to either the fulfilled or rejected state', function()
	local d = deferred.new()
	ok(d.state == 0, 'default state is pending')
	d:resolve()
	ok(d.state == 3, 'transition to RESOLVED')
	d = deferred.new()
	d:reject()
	ok(d.state == 4, 'transition to REJECTED')
end)

test('A+ 2.1.2.1 fulfilled promise must not transition to any other state', function()
	local d = deferred.new():resolve('foo')
	d:reject('foo')
	ok(d.state == 3, 'state is still RESOLVED')
end)

test('A+ 2.1.2.2 fulfilled promise must have a value which must not change', function()
	local d = deferred.new():resolve('foo')
	ok(d.value == 'foo', 'has a value')
	d:resolve('bar')
	d:reject('baz')
	ok(d.value == 'foo', 'value does not change')
end)

test('A+ 2.1.3.1 rejected promise must have a reason which must not change', function()
	local d = deferred.new():reject('foo')
	ok(d.value == 'foo', 'has a reason')
	d:resolve('bar')
	d:reject('baz')
	ok(d.value == 'foo', 'reason does not change')
end)

test('A+ 2.2.1 both callbacks are optional and may not be functions', function()
	local d = deferred.new()
	d:next(23)
	d:resolve('foo')
	d = deferred.new()
	d:next()
	d:reject('foo')
end)

test('A+ 2.2.2 fulfilled callback', function()
	local d = deferred.new()
	local f = spy()
	d:next(f)
	ok(not f.called, 'not called before promise is fulfilled')
	d:resolve('foo')
	ok(f.called ~= nil, 'called after the promise is fulfilled')
	ok(f.called[1][1] == 'foo', 'value matches')
	d:resolve('foo')
	d:reject('foo')
	ok(#f.called == 1, 'called only once')
end)

test('A+ 2.2.3 rejected callback', function()
	local d = deferred.new()
	local f = spy()
	d:next(nil, f)
	ok(not f.called, 'not called before promise is rejected')
	d:reject('foo')
	ok(f.called ~= nil, 'called after the promise is rejected')
	ok(f.called[1][1] == 'foo', 'value matches')
	d:reject('foo')
	d:resolve('foo')
	ok(#f.called == 1, 'called only once')
end)

test('A+ 2.2.6 multiple thens', function()
	local d = deferred.new()
	local f1, f2
	f1 = spy(function() ok(not f2.called, 'order is correct') end)
	f2 = spy(function() ok(f1.called, 'order is correct') end)
	d:next(f1)
	d:next(f2)
	d:resolve('foo')
	ok(#f1.called == 1 and f1.called[1][1] == 'foo', 'first thennable called')
	ok(#f2.called == 1 and f2.called[1][1] == 'foo', 'second thennable called')

	d = deferred.new()
	f1 = spy(function() ok(not f2.called, 'order is correct') end)
	f2 = spy(function() ok(f1.called, 'order is correct') end)
	d:next(nil, f1)
	d:next(nil, f2)
	d:reject('foo')
	ok(#f1.called == 1 and f1.called[1][1] == 'foo', 'first rejection thennable called')
	ok(#f2.called == 1 and f2.called[1][1] == 'foo', 'second rejection thennable called')
end)

test('A+ 2.2.7 then must return a promise', function()
	local d = deferred.new()
	local t = d:next()
	ok(type(t) == 'table' and type(t.next) == 'function', 'is a promise')
end)

test('A+ 2.2.7 value propagation', function()
	local d = deferred.new()
	local f1 = spy(function(v) return 'bar' end)
	local f2 = spy()
	d:next(f1):next(f2)
	d:resolve('foo')
	ok(f1.called[1][1] == 'foo', 'value proparated to the first callback')
	ok(f2.called[1][1] == 'bar', 'value proparated from the first callback to the second one')
end)

test('A+ 2.2.7 error propagation', function()
	local d = deferred.new()
	local f1 = spy()
	local f2 = spy()
	local f3 = spy()
	local f4 = spy()
	d:next(function(v) f1(v); error('bar', 0) end):next(nil, f2):next(f3, f4)
	d:resolve('foo')
	ok(f1.called[1][1] == 'foo', 'value proparated to the first callback')
	ok(f2.called[1][1] == 'bar', 'error proparated')
	ok(f3.called[1][1] == nil, 'nil value proparated')
	ok(not f4.called, 'no error was proparated')
end)

test('A+ 2.2.7 propagation through non-functions', function()
	local d = deferred.new()
	local f
	f = spy()
	d:next():next(f)
	d:resolve('foo')
	ok(f.called[1][1] == 'foo', 'value proparated to the second callback')
end)

test('A+ 2.3 promise return self', function()
	local d = deferred.new()
	local p
	local f1 = spy()
	local f2 = spy()
	p = d:next(function() return p end)
	p:next(f1, f2)
	d:resolve('fizz')
	ok(not f1.called and f2.called, 'resolving promise with itself rejects it')
end)

test('A+ 2.3.2 return promise and resolve it', function()
	local d1 = deferred.new()
	local d2 = deferred.new()
	local p1, p2
	local f1 = spy(function(v) return d2 end)
	local f2 = spy()

	d1:next(f1):next(f2)
	d1:resolve('foo')
	ok(f1.called[1][1] == 'foo', 'first promise resolved')
	ok(not f2.called, 'second promise pending')
	d2:resolve('bar')
	ok(f2.called[1][1] == 'bar', 'second promise resolved')
end)

test('A+ 2.3.2 return promise and reject it', function()
	local d1 = deferred.new()
	local d2 = deferred.new()
	local p1, p2
	local f1 = spy(function(v) return d2 end)
	local f2 = spy()
	local f3 = spy()

	d1:next(f1):next(f2, f3)
	d1:resolve('foo')
	ok(f1.called[1][1] == 'foo', 'first promise resolved')
	ok(not f2.called, 'second promise pending')
	d2:reject('bar')
	ok(not f2.called and f3.called[1][1] == 'bar', 'second promise rejected')
end)

test('A+ 2.3.3 custom thennable', function()
	local d = deferred.new()
	local f1 = spy()
	local f2 = spy()
	d:next(function()
		return {
			next = function(self, resolve, reject)
				resolve('foo')
				reject('bar')
			end
		}
	end):next(f1, f2)
	d:resolve()
	ok(f1.called[1][1] == 'foo' and not f2.called, 'resolved')
	
	d = deferred.new()
	f1 = spy()
	f2 = spy()
	d:next(function()
		return { next = function(self, resolve, reject) resolve('foo'); error('baz', 0) end }
	end):next(f1, f2)
	d:resolve()
	ok(f1.called[1][1] == 'foo' and not f2.called, 'resolved')

	d = deferred.new()
	f1 = spy()
	f2 = spy()
	d:next(function()
		return { next = function(self, resolve, reject) reject('baz') end }
	end):next(f1, f2)
	d:resolve()
	ok(f2.called[1][1] == 'baz' and not f1.called, 'rejected')

	d = deferred.new()
	f1 = spy()
	f2 = spy()
	d:next(function()
		return { next = function(self, resolve, reject) error('baz', 0) end }
	end):next(f1, f2)
	d:resolve()
	ok(f2.called[1][1] == 'baz' and not f1.called, 'rejected')
end)

test('A+ 2.3.3 table looking like thenable', function()
	local d = deferred.new()
	local f1 = spy()
	local f2 = spy()
	d:next(function()
		return { next = {'bar'}}
	end):next(f1, f2)
	d:resolve()
	ok(f1.called[1][1].next[1] == 'bar' and not f2.called, 'rejected')
end)

test('A+ 2.3.3 simple resolve', function()
	local d = deferred.new()
	local f1 = spy()
	local f2 = spy()
	d:next(function()
		return 'foo'
	end):next(f1, f2)
	d:resolve()
	ok(f1.called[1][1] == 'foo' and not f2.called, 'resolved')
end)

test('Custom promises', function()
	local d = deferred.new({extend = function(n)
		n.foo = 'hello'
		n.bar = function()
			return n.foo
		end
	end})
	local p1 = d:next()
	local p2 = p1:next()
	ok(p1.foo == 'hello' and p1.bar() == 'hello', 'first custom promise')
	p1.foo = 'world' -- should not mutate second promise
	ok(p2.foo == 'hello' and p2.bar() == 'hello', 'second custom promise')
end)

test('Parallel promises resolution', function()
	local a = deferred.new()
	local b = deferred.new()
	local c = deferred.new()
	local d = deferred.all({a, b, c})
	
	local f1 = spy()
	local f2 = spy()
	d:next(f1, f2)

	a:resolve('foo')
	b:resolve('bar')
	ok(not f1.called and not f2.called, 'not all promises are resolved yet')
	c:resolve('baz')
	ok(f1.called and not f2.called, 'all promises resolved successfully')
	ok(eq(f1.called[1][1], {'foo', 'bar', 'baz'}), 'all promises resolved with correct values')
end)

test('Parallel promises rejection', function()
	local a = deferred.new()
	local b = deferred.new()
	local c = deferred.new()
	local d = deferred.all({a, b, c})
	
	local f1 = spy()
	local f2 = spy()
	d:next(f1, f2)

	a:resolve('foo')
	b:reject('bar')
	ok(not f1.called and not f2.called, 'not all promises are resolved yet')
	c:resolve('baz')
	ok(not f1.called and f2.called, 'all promises are resolved/rejected')
	ok(eq(f2.called[1][1], {'foo', 'bar', 'baz'}), 'promise values are correct')
end)

test('Sequential mapping of promises', function()
	local function len(s)
		local d = deferred.new()
		d:resolve(#s)
		return d
	end

	local f = spy(function(res)
		ok(#res == 3, 'all promises are resolved')
		ok(res[1] == 3 and res[2] == 6 and res[3] == 5, 'promise values are correct')
	end)

	deferred.map({'foo', 'barbaz', 'hello'}, len):next(f)
	ok(f.called, 'wrapper promise is called')
end)

test('Race of resolved promises', function()
	local a = deferred.new()
	local b = deferred.new();

	local c = deferred.first({a, b})
	local f = spy()

	c:next(f)
	a:resolve('foo')
	b:resolve('bar')
	ok(#f.called == 1, 'race promise was called once')
	ok(f.called[1][1] == 'foo', 'promise was called with the first resolved value')
end)

test('Race of rejected promises', function()
	local a = deferred.new()
	local b = deferred.new();

	local c = deferred.first({a, b})
	local f = spy()
	local g = spy()

	c:next(f, g)
	a:reject('foo')
	b:resolve('bar')
	ok(not f.called, 'race promise was not resolved once')
	ok(#g.called == 1, 'race promise was rejected once')
	ok(g.called[1][1] == 'foo', 'promise was rejected with the first error')
end)

if tests_failed > 0 then os.exit(1) end
