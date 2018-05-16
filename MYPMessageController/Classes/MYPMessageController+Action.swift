//
//  MYPMessageController+Action.swift
//  MYPMessageController
//
//  Created by wakary redou on 2018/5/16.
//

import Foundation

extension MYPMessageController {
    
    //MARK: Interaction Notifications
    /**
     Changes the visibility of the text input bar.
     Calling this method with the animated parameter set to NO is equivalent to setting the value of the toolbarHidden property directly.
     
     - Parameters:
     - hidden: Specify true to hide the toolbar or false to show it.
     - animated: Specify true if you want the toolbar to be animated on or off the screen.
     */
    open func setTextInputbarHidden(_ hidden: Bool, animated: Bool) {
        if self.textInputbarHidden == hidden {
            return
        }
        
        self.textInputbar.isHidden = hidden
        
        if #available(iOS 11.0, *) {
            self.viewSafeAreaInsetsDidChange()
        }
        
        weak var weakSelf = self
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                weakSelf!.textInputbarHeightC.constant = hidden ? 0.0 : weakSelf!.textInputbar.appropriateHeight
                weakSelf!.view.layoutIfNeeded()
            }) { (finished) in
                if hidden {
                    self.dismissKeyboard(animated: true)
                }
            }
        }
        else {
            self.textInputbarHeightC.constant = hidden ? 0.0 : self.textInputbar.appropriateHeight
            self.view.layoutIfNeeded()
            
            if hidden {
                self.dismissKeyboard(animated: false)
            }
        }
        
    }
    
    /**
     Notifies the view controller that the text will update.
     You can override this method to perform additional tasks associated with text changes.
     You MUST call super at some point in your implementation.
     */
    open func textWillUpdate() {
        // do nothing here. override it in subclass
    }
    
    /**
     Notifies the view controller that the text did update.
     You can override this method to perform additional tasks associated with text changes.
     You MUST call super at some point in your implementation.
     
     - Parameters:
     - animated: If true, the text input bar will be resized using an animation.
     */
    open func textDidUpdate(animated: Bool) {
        
        if self.textInputbarHidden {
            return
        }
        
        let inputBarHeight = self.textInputbar.appropriateHeight
        
        // update input bar height here
        if inputBarHeight != self.textInputbarHeightC.constant {
            
            let heightDelta = inputBarHeight - self.textInputbarHeightC.constant
            let newOffset = CGPoint(x: 0, y: self.scrollViewProxy!.contentOffset.y + heightDelta)
            self.textInputbarHeightC.constant = inputBarHeight
            self.scrollViewHeightC.constant = self.myp_appropriateScrollViewHeight()
            
            if animated {
                let shouldBounces = self.bounces && self.textView.isFirstResponder
                
                self.view.myp_animateLayoutIfNeeded(withBounce: shouldBounces, options: [UIViewAnimationOptions.curveEaseInOut, .layoutSubviews, .beginFromCurrentState], animations: {
                    if !self.isInverted {
                        self.scrollViewProxy?.contentOffset = newOffset
                    }
                })
            }
            else {
                self.view.layoutIfNeeded()
            }
        }
        
        // Toggles auto-correction if requiered
        self.myp_enableTypingSuggestionIfNeeded()
    }
    
    /**
     Notifies the view controller that the text selection did change.
     Use this method a replacement of UITextViewDelegate's -textViewDidChangeSelection: which is not reliable enough when using third-party keyboards (they don't forward events properly sometimes).
     
     You can override this method to perform additional tasks associated with text changes.
     You MUST call super at some point in your implementation.
     */
    open func textSelectionDidChange() {
        // The text view must be first responder
        if !self.textView.isFirstResponder || self.keyboardStatus != .didShow {
            return
        }
        
        // Skips there is a real text selection
        if self.textView.isTrackpadEnabled {
            return
        }
        
        if self.textView.selectedRange.length > 0 {
            if self.isAutoCompleting && self.shouldProcessTextForAutoCompletion() {
                self.cancelAutoCompletion()
            }
            return
        }
        
        // Process the text at every caret movement
        self.myp_processtextForAutoCompletion()
    }
    
    /**
     Notifies the view controller when the left button's action has been triggered, manually.
     You can override this method to perform additional tasks associated with the left button.
     You don't need call super since this method doesn't do anything.
     */
    @objc open func didPressLeftButton(sender: UIButton) {
        // if could or should, change the image of button
    }
    
    @objc open func didPressRightButton(sender: UIButton) {
        // if could or should, change the image of button
    }
    
    @objc open func didPressRightMoreButton(sender: UIButton) {
        // if could or should, change the image of button
    }
    
    /**
     Notifies the view controller when the send button's action has been triggered, manually or by using the keyboard return key.
     You can override this method to perform additional tasks associated with the send button.
     You MUST call super at some point in your implementation.
     */
    @objc open func didPressSendButton(sender: UIButton) {
        if self.shouldClearTextAtSendButtonPress {
            self.textView.myp_clearText(shouldClearUndo: true)
        }
        
        // Clears cache
        self.clearCachedText()
        
    }
    
    /**
     Verifies if the right button can be pressed. If false, the button is disabled.
     You can override this method to perform additional tasks. You SHOULD call super to inherit some conditionals.
     We do not use it here. we use shouldEnableSendButton in MYPTextInputbarView.
     we could open this api to enable/disable outside MYPTextInputbarView, and remove the inside control.
     
     - Returns: true if the right button can be pressed.
     */
    open func canPressSendButton() -> Bool {
        let text = self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if text.count > 0 && !self.textInputbar.isLimitExceeded {
            return true
        }
        return false
    }
    
    private func myp_performSendAction() {
        let actions = self.sendButton.actions(forTarget: self, forControlEvent: .touchUpInside)
        
        if actions?.count ?? 0 > 0 && self.canPressSendButton() {
            self.sendButton.sendActions(for: .touchUpInside)
        }
    }
    
    /**
     Notifies the view controller when the user has pasted a supported media content (images and/or videos).
     Not supported yet now.
     You can override this method to perform additional tasks associated with image/video pasting.
     You don't need to call super since this method doesn't do anything.
     Only supported pastable medias configured in MYPTextView will be forwarded (take a look at MYPPastableMediaType).
     
     - Parameters:
     - userInfo: The payload containing the media data, content and media types.
     */
    open func didPasteMediaContent(userInfo: [String: Any]) {
        // not supported yet now
    }
    
    /**
     Notifies the view controller when the user has shaked the device for undoing text typing.
     You can override this method to perform additional tasks associated with the shake gesture.
     Calling super will prompt a system alert view with undo option. This will not be called if 'undoShakingEnabled' is set to false and/or if the text view's content is empty.
     */
    open func willRequestUndo() {
        let aTitle = NSLocalizedString("Undo Typing", comment: "")
        let acceptTitle = NSLocalizedString("Undo", comment: "")
        let cancelTitle = NSLocalizedString("Cancel", comment: "")
        
        let alertController = UIAlertController(title: aTitle, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: acceptTitle, style: .default, handler: {(_ action: UIAlertAction?) -> Void in
            // Clears the text but doesn't clear the undo manager
            if self.isShakeToClearEnabled {
                self.textView.myp_clearText(shouldClearUndo: false)
            }
        }))
        alertController.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: nil))
        present(alertController, animated: true) {() -> Void in }
    }
    
    //MARK: keyboard handling
    /**
     Notifies the view controller that the keyboard changed status.
     You can override this method to perform additional tasks associated with presenting the view.
     You don't need call super since this method doesn't do anything.
     */
    open func keyboardDidChange(status: MYPKeyboardStatus) {
        // do nothing here. override it in subclass
    }
    
    /**
     Presents the keyboard, if not already, animated.
     You can override this method to perform additional tasks associated with presenting the keyboard.
     You SHOULD call super to inherit some conditionals.
     */
    open func presentKeyboard(animated: Bool) {
        // Skips if already first responder
        if self.textView.isFirstResponder {
            return
        }
        
        if !animated {
            UIView.performWithoutAnimation {
                _ = self.textView.becomeFirstResponder()
            }
        }
        else {
            _ = self.textView.becomeFirstResponder()
        }
    }
    
    /**
     Dimisses the keyboard, if not already, animated.
     You can override this method to perform additional tasks associated with dismissing the keyboard.
     You SHOULD call super to inherit some conditionals.
     */
    open func dismissKeyboard(animated: Bool) {
        if !self.textView.isFirstResponder && self.keyboardHeightC.constant > 0 {
            self.view.window?.endEditing(false)
        }
        
        if !animated {
            UIView.performWithoutAnimation {
                _ = self.textView.resignFirstResponder()
            }
        }
        else {
            _ = self.textView.resignFirstResponder()
        }
    }
    
    /**
     Verifies if the text input bar should still move up/down even if it is NOT first responder.
     Default is false.
     You can override this method to perform additional tasks associated with presenting the view.
     You don't need call super since this method doesn't do anything.
     
     - Parameters:
     - responder: The current first responder object.
     - Returns: true so the text input bar still move up/down.
     */
    open func forceTextInputbarAdjustment(for responder: UIResponder?) -> Bool {
        return false
    }
    
    /**
     Verifies if the text input bar should still move up/down when the text view is first responder.
     This is very useful when presenting the view controller in a custom modal presentation, when there keyboard events are being handled externally to reframe the presented view.
     You SHOULD call super to inherit some conditionals.
     
     - Returns: true so the text input bar still move up/down.
     */
    open func ignoreTextInputbarAdjustment() -> Bool {
        if self.isExternalKeyboardDetected || self.isKeyboardUndocked {
            return true
        }
        
        return false
    }
    
    //MARK: Keyboard Events
    /**
     Notifies the view controller when the user has pressed the Return key (↵) with an external keyboard.
     You can override this method to perform additional tasks.
     You MUST call super at some point in your implementation.
     
     - Parameters:
     - keyCommand: The UIKeyCommand object being recognized.
     */
    open func didPressReturnKey(_ keyCommand: UIKeyCommand?) {
        // TODO: we need to change it into insert "\n", not a send action
        self.myp_performSendAction()
    }
    
    /**
     Notifies the view controller when the user has pressed the Escape key (Esc) with an external keyboard.
     You can override this method to perform additional tasks.
     You MUST call super at some point in your implementation.
     
     - Parameters:
     - keyCommand: The UIKeyCommand object being recognized.
     */
    open func didPressEscapeKey(_ keyCommand: UIKeyCommand?) {
        if self.isAutoCompleting {
            self.cancelAutoCompletion()
        }
        
        let bottomMargin = self.myp_appropriateBottomMargin()
        
        if self.ignoreTextInputbarAdjustment() || (self.textView.isFirstResponder && self.keyboardHeightC.constant == bottomMargin) {
            return
        }
        
        self.dismissKeyboard(animated: true)
    }
    
    /**
     Notifies the view controller when the user has pressed the arrow key with an external keyboard.
     You can override this method to perform additional tasks.
     You MUST call super at some point in your implementation.
     
     - Parameters:
     - keyCommand: The UIKeyCommand object being recognized.
     */
    open func didPressArrowKey(_ keyCommand: UIKeyCommand?) {
        if keyCommand == nil {
            return
        }
        self.textView.didPressArrowKey(keyCommand!)
    }
    
}
