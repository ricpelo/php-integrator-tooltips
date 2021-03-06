Utility = require './Utility'
AbstractProvider = require './AbstractProvider'

module.exports =

##*
# Provides tooltips for global constants.
##
class ClassProvider extends AbstractProvider
    ###*
     * @inheritdoc
    ###
    hoverEventSelectors: '.function-call.object, .function-call.static'

    ###*
     * @inheritdoc
    ###
    getTooltipForWord: (editor, bufferPosition, name) ->
        try
            value = @service.getClassMethodAt(editor, bufferPosition, name)

        catch error
            return null

        return unless value

        return Utility.buildTooltipForFunction(value)
