{TextEditor} = require 'atom'

$ = require 'jquery'
SubAtom = require 'sub-atom'

module.exports =

##*
# Base class for providers.
##
class AbstractProvider
    ###*
     * The class selectors for which a hover event will be triggered.
    ###
    hoverEventSelectors: ''

    ###*
     * The service (that can be used to query the source code and contains utility methods).
    ###
    service: null

    ###*
     * Initializes this provider.
     *
     * @param {mixed} service
    ###
    activate: (service) ->
        @service = service
        @subAtom = new SubAtom

        atom.workspace.observeTextEditors (editor) =>
            @registerEvents(editor)

        # When you go back to only have one pane the events are lost, so need to re-register.
        atom.workspace.onDidDestroyPane (pane) =>
            panes = atom.workspace.getPanes()

            if panes.length == 1
                @registerEventsForPane(panes[0])

        # Having to re-register events as when a new pane is created the old panes lose the events.
        atom.workspace.onDidAddPane (observedPane) =>
            panes = atom.workspace.getPanes()

            for pane in panes
                if pane != observedPane
                    @registerEventsForPane(pane)

    ###*
     * Registers the necessary event handlers for the editors in the specified pane.
     *
     * @param {Pane} pane
    ###
    registerEventsForPane: (pane) ->
        for paneItem in pane.items
            if paneItem instanceof TextEditor
                @registerEvents(paneItem)

    ###*
     * Deactives the provider.
    ###
    deactivate: () ->
        @subAtom.dispose()
        @removePopover()

    ###*
     * Registers the necessary event handlers.
     *
     * @param {TextEditor} editor TextEditor to register events to.
    ###
    registerEvents: (editor) ->
        if editor.getGrammar().scopeName.match /text.html.php$/
            textEditorElement = atom.views.getView(editor)
            scrollViewElement = $(textEditorElement.shadowRoot).find('.scroll-view')

            @subAtom.add scrollViewElement, 'mouseover', @hoverEventSelectors, (event) =>
                selector = @getSelectorFromEvent(event)

                if selector == null
                    return

                editorViewComponent = atom.views.getView(editor).component

                # Ticket #140 - In rare cases the component is null.
                if editorViewComponent
                    cursorPosition = editorViewComponent.screenPositionForMouseEvent(event)

                    @removePopover()
                    @showPopoverFor(editor, selector, cursorPosition)

            @subAtom.add scrollViewElement, 'mouseout', @hoverEventSelectors, (event) =>
                @removePopover()

            # Ticket #107 - Mouseout isn't generated until the mouse moves, even when scrolling (with the keyboard or
            # mouse). If the element goes out of the view in the meantime, its HTML element disappears, never removing
            # it.
            editor.onDidDestroy () =>
                @removePopover()

            editor.onDidStopChanging () =>
                @removePopover()

            $(textEditorElement.shadowRoot).find('.horizontal-scrollbar').on 'scroll', () =>
                @removePopover()

            $(textEditorElement.shadowRoot).find('.vertical-scrollbar').on 'scroll', () =>
                @removePopover()

    ###*
     * Shows a popover containing the documentation of the specified element located at the specified location.
     *
     * @param {TextEditor} editor         TextEditor containing the elemment.
     * @param {string}     element        The element to search for.
     * @param {Point}      bufferPosition The cursor location the element is at.
     * @param {int}        delay          How long to wait before the popover shows up.
     * @param {int}        fadeInTime     The amount of time to take to fade in the tooltip.
    ###
    showPopoverFor: (editor, element, bufferPosition, delay = 500, fadeInTime = 100) ->
        name = $(element).text()
        tooltipText = @getTooltipForWord(editor, bufferPosition, name)

        if tooltipText?.length > 0
            popoverElement = @getPopoverElementFromSelector(element)

            @attachedPopover = @service.createAttachedPopover(popoverElement)
            @attachedPopover.setText('<div style="margin-top: -1em;">' + tooltipText + '</div>')
            @attachedPopover.showAfter(delay, fadeInTime)

    ###*
     * Removes the popover, if it is displayed.
    ###
    removePopover: () ->
        if @attachedPopover
            @attachedPopover.dispose()
            @attachedPopover = null

    ###*
     * Retrieves a tooltip for the word given.
     *
     * @param {TextEditor} editor         TextEditor to search for namespace of term.
     * @param {Point}      bufferPosition The cursor location the term is at.
     * @param {string}     name           The name of the element to retrieve the tooltip for.
    ###
    getTooltipForWord: (editor, bufferPosition, name) ->
        throw new Error("This method is abstract and must be implemented!")

    ###*
     * Gets the correct selector when a selector is clicked.
     * @param  {jQuery.Event}  event  A jQuery event.
     * @return {object|null}          A selector to be used with jQuery.
    ###
    getSelectorFromEvent: (event) ->
        return event.currentTarget

    ###*
     * Gets the correct element to attach the popover to from the retrieved selector.
     * @param  {jQuery.Event}  event  A jQuery event.
     * @return {object|null}          A selector to be used with jQuery.
    ###
    getPopoverElementFromSelector: (selector) ->
        return selector
