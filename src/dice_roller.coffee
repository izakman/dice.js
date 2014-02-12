
class Die
  constructor: (@numOfSides) ->
    @sides = [1..@numOfSides]
    @result = null
  
  roll: (times) =>
    throw new RangeError("Argument can't be 0") if times is 0
    times = if times > 1 then times else 1
    return new RollResult(this, (@sides[Math.floor(Math.random() * @numOfSides)] for [1..times]))
  
  toString: () =>
    return "d#{@numOfSides}"
  
  isSameAs: (die) =>
    throw new TypeError("Argument should be a Die object") unless die instanceof Die
    return @sides.join(',') is die.sides.join(',')
  
  another: () =>
    return new Die(@numOfSides)
  
  @roll: (sides, times) ->
    return new Die(sides).roll(times)

class RollResult
  constructor: (@die, @rolls) ->
    throw new SyntaxError("First argument must a Die object") unless @die instanceof Die
    throw new SyntaxError("Second argument must be an array") unless Object.prototype.toString.call(@rolls) is '[object Array]'
    @total = 0
    @total += roll for roll in @rolls
    @times = @rolls.length
  
  toString: () =>
    rollsString = if @rolls.length > 1 then "{#{@rolls.join("+")}}" else ""
    timesString = if @times > 1 then "#{@times}" else ""
    return "#{@total}[#{timesString}d#{@die.numOfSides}#{rollsString}]"

class RollExpressionResult
  parseDice = (diceExp) ->
    return null unless /^([1-9][0-9]*)?(d)([1-9][0-9]*)$/.test(diceExp)
    values = diceExp.split("d")
    return Die.roll(values[1], if values[0] then values[0] else 1)
  
  parseModifier = (modExp) ->
    return (if /^(0|[1-9](\d*))$/.test(modExp) then parseInt(modExp) else null)
  
  parseOperator = (operatorExp) -> (if operatorExp is '+' or operatorExp is '-' then operatorExp else null)
  
  constructor: (@stringExpression) ->
    @total = 0
    @results = []
    
    prevOperator = '+'
    expressionArray = @stringExpression.split(" ")
    
    for exp in expressionArray
      expResult = parseModifier(exp) or parseDice(exp) or parseOperator(exp) or null
      throw new SyntaxError("\"#{exp}\" is not valid") unless expResult?
      @results.push(expResult)
      
      if parseOperator(expResult)
        prevOperator = expResult
        continue 
      
      value = (if expResult instanceof RollResult then expResult.total else expResult)
      
      if prevOperator is '+'
        @total += value
      else
        @total -= value
  
  toString: () =>
    return "#{@total}: #{(exp.toString() for exp in @results).join(" ")}"
      

class DiceCollection
  constructor: (dice...) ->
    @dice = []
    @add(dice) if dice?
  
  add: (dice...) =>
    throw new SyntaxError("add() must have at least one argument") unless dice?
    dice = dice[0] if Object.prototype.toString.call(dice[0]) is '[object Array]'
    for die in dice
      throw new TypeError("Arguments should be Die objects or an Array of Die objects") unless die instanceof Die
      @dice.push(die)
    
  remove: (dice...) =>
    throw new SyntaxError("remove() must have at least one argument") unless dice?
    dice = dice[0] if Object.prototype.toString.call(dice[0]) is '[object Array]'
    isInt = (val) -> (typeof val is 'number') and (val % 1 is 0) # Helper to check if value is integer
    removedDice = []
    if isInt(dice[0])
      for diceIndex in dice
        throw new TypeError("Provided Array elements should all be integers") unless isInt(diceIndex)
        removedDice.push(@dice.splice(diceIndex, 1))
    else
      for die in dice
        throw new TypeError("Arguments should be Die objects") unless die instanceof Die
        for original, index in @dice
          if original.isSameAs(die)
            removedDice.push(@dice.splice(index, 1))
            break
    throw new RangeError("Die not in DiceCollection") if removedDice.length is 0
    return if removedDice.length is 1 then removedDice[0] else new DiceCollection(removedDice)
  
  grab: (number) =>
    indexes = (Math.floor(Math.random() * @dice.length) for [1..number])
    return remove(indexes)
  
  roll: (times, giveTotals, allTotaled) =>
    throw new RangeError("Argument can't be 0") if times is 0
    rollOnce = () => (die.roll() for die in @dice)
    getTotal = (roll) => total = 0; total += val for val in roll; return total
    if times > 1
      rolls = for [1..times]
        if giveTotals then getTotal(rollOnce()) else rollOnce()
      return if allTotaled then getTotal(rolls) else rolls
    else
      return if giveTotals then getTotal(rollOnce()) else rollOnce()

parse = (diceExpressionString) ->
  return new RollExpressionResult(diceExpressionString)

d = (sides) ->
  return new Die(sides)

module.exports = {
  Die: Die,
  DiceCollection: DiceCollection,
  RollResult: RollResult,
  RollExpressionResult: RollExpressionResult,
  parse: parse,
  d: d
}