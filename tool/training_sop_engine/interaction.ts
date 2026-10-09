import { Extension } from '@tiptap/core';
import { Plugin, TextSelection } from '@tiptap/pm/state';

export const SopInteraction = Extension.create({
  name: 'sopInteraction',
  addCommands() {
    return {
      blur: () => ({ dispatch, editor, view }) => {
        // The engine probes every command with can() while publishing toolbar
        // state. Tiptap's default blur also schedules a real blur during that
        // dry run, removing the native keyboard/caret after every selection.
        if (dispatch) requestAnimationFrame(() => {
          if (!editor.isDestroyed) {
            view.dom.blur();
            view.dom.ownerDocument.getSelection()?.removeAllRanges();
          }
        });
        return true;
      },
    };
  },
  addProseMirrorPlugins() {
    // The first short tap focuses without WebKit's form zoom. If it starts a
    // double tap, complete its word selection ourselves because cancelling the
    // first touch also cancels native double-tap recognition. Later selections,
    // drags, long presses and pinches keep their native handling.
    let focusTap: { x: number; y: number; time: number } | undefined;
    let tap: { x: number; y: number; time: number; selectWord: boolean } | undefined;
    const words = new Intl.Segmenter(undefined, { granularity: 'word' });
    return [new Plugin({
      props: {
        handleDOMEvents: {
          touchstart(view, event) {
            const target = event.target instanceof Element ? event.target : undefined;
            const touch = event.touches[0];
            const now = Date.now();
            const selectWord = !!(touch && focusTap && view.hasFocus() && now - focusTap.time < 400 &&
              Math.hypot(touch.screenX - focusTap.x, touch.screenY - focusTap.y) < 20);
            tap = view.editable && (!view.hasFocus() || selectWord) && event.touches.length === 1 &&
              !target?.closest('a, input, button, label, img') ?
              { x: touch.screenX, y: touch.screenY, time: now, selectWord } : undefined;
            focusTap = undefined;
            return false;
          },
          touchmove(_, event) {
            const touch = event.touches[0];
            if (tap && (!touch || event.touches.length !== 1 ||
              Math.hypot(touch.screenX - tap.x, touch.screenY - tap.y) > 10)) tap = undefined;
            return false;
          },
          touchcancel() { tap = undefined; return false; },
          touchend(view, event) {
            const start = tap;
            tap = undefined;
            if (!start || event.touches.length || Date.now() - start.time > 500 || !view.editable) return false;
            const touch = event.changedTouches[0];
            if (!touch) return false;
            const hit = view.posAtCoords({ left: touch.clientX, top: touch.clientY });
            if (!hit) return false;
            event.preventDefault();
            const position = view.state.doc.resolve(hit.pos);
            let selection = TextSelection.near(position);
            if (start.selectWord && position.parent.isTextblock) {
              const text = position.parent.textBetween(0, position.parent.content.size, '', '\ufffc');
              for (const word of words.segment(text)) {
                if (word.isWordLike && word.index <= position.parentOffset &&
                  word.index + word.segment.length >= position.parentOffset) {
                  selection = TextSelection.create(view.state.doc, position.start() + word.index,
                    position.start() + word.index + word.segment.length);
                  break;
                }
              }
            }
            view.dispatch(view.state.tr.setSelection(selection).setMeta('pointer', true));
            // Focus synchronously within the user gesture so iOS opens its
            // keyboard, then sync the DOM caret from the tapped document position.
            // preventScroll also suppresses WebKit's automatic focus zoom.
            view.dom.focus({ preventScroll: true });
            view.focus();
            if (!start.selectWord) focusTap = { x: start.x, y: start.y, time: Date.now() };
            return true;
          },
        },
      },
    })];
  },
});
