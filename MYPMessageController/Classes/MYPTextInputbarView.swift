//
//  MYPTextInputbarView.swift
//  MYPTextInputVC
//
//  Created by wakary redou on 2018/5/8.
//  Copyright © 2018年 wakary redou. All rights reserved.
//

import UIKit

/**
 Here we use the textView's intrinsic content size for textView and button's initial height.
 
 height = 8 + 0 + 1 * 2 + textViewHeight.
 textViewHeight = textHeight + containerInset.
*/
@IBDesignable
class MYPTextInputbarView: UIView {
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var rightMoreButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textView: MYPTextView!
    
    @IBOutlet weak var topDivider: UIView!
    @IBOutlet weak var bottomDivider: UIView!
    
    @IBOutlet weak var topDividerHeightC: NSLayoutConstraint!
    @IBOutlet weak var bottomDividerHeightC: NSLayoutConstraint!
    
    @IBOutlet weak var leftButtonWidthC: NSLayoutConstraint!
    // to leftButton
    @IBOutlet weak var textViewLeftLeadingC: NSLayoutConstraint!
    // to rightButton
    @IBOutlet weak var textViewRightTrailingC: NSLayoutConstraint!
    @IBOutlet weak var rightButtonWidthC: NSLayoutConstraint!
    @IBOutlet weak var rightMoreButtonWidthC: NSLayoutConstraint!
    @IBOutlet weak var sendButtonWidthC: NSLayoutConstraint!
    // to sendButton or rightMoreButton
    @IBOutlet weak var rightButtonTrailingC: NSLayoutConstraint!
    
    //contentInset
    @IBOutlet weak var contentLeftLeadingC: NSLayoutConstraint!
    @IBOutlet weak var contentBottomMarginC: NSLayoutConstraint!
    @IBOutlet weak var contentRightTrailingC: NSLayoutConstraint!
    @IBOutlet weak var contentTopMarginC: NSLayoutConstraint!
    
    // we change the button size height and width into textView's minimumHeight in the commonSetting
    @IBOutlet weak var actionButtonHeightC: NSLayoutConstraint!
    
    private var initialButtonMargin: CGFloat = 0.0
    private var initialButtonWidth: CGFloat = 0.0
    private var initialSendButtonWidth: CGFloat = 0.0
    
    private var previousOrigin = CGPoint.zero
    
    /**used to set the image of left button or hide it.
     set it nil or blank will hide the leftButton.
     set non-nil or non-blank will change the image of the left button.
     Default, it will show the default left button.
     The button height is almost 32-36. We could make the image size (36, 36)
     */
    var leftButtonImageName: String? = "_myp_xxoox0x_" {
        didSet {
            if leftButtonImageName == oldValue {
                return
            }
            if leftButtonImageName == nil || leftButtonImageName == "" {
                self.leftButtonWidthC.constant = 0
                self.textViewLeftLeadingC.constant = 0
                return
            }
            if oldValue == nil || oldValue == "" {
                self.leftButtonWidthC.constant = self.initialButtonWidth
                self.textViewLeftLeadingC.constant = self.initialButtonMargin
            }
            self.leftButton.setImage(UIImage(named: self.leftButtonImageName!), for: .normal)
        }
    }
    
    var rightButtonImageName: String? = "_myp_xxoox0x_" {
        didSet {
            if rightButtonImageName == oldValue {
                return
            }
            if rightButtonImageName == nil || rightButtonImageName == "" {
                self.rightButtonWidthC.constant = 0
                self.textViewRightTrailingC.constant = 0
                return
            }
            if oldValue == nil || oldValue == "" {
                self.rightButtonWidthC.constant = self.initialButtonWidth
                self.textViewRightTrailingC.constant = self.initialButtonMargin
            }
            self.rightButton.setImage(UIImage(named: rightButtonImageName!), for: .normal)
        }
    }
    
    var rightMoreButtonImageName: String? = "_myp_xxoox0x_" {
        didSet {
            if rightMoreButtonImageName == oldValue {
                return
            }
            self.myp_updateSendButtonsConstraints()
            /*
            if rightMoreButtonImageName == nil || rightMoreButtonImageName == "" {
                self.rightMoreButtonWidthC.constant = 0
            }
            if oldValue == nil || oldValue == "" {
                self.rightMoreButtonWidthC.constant = self.initialButtonWidth
            }
            self.rightMoreButton.setImage(UIImage(named: rightMoreButtonImageName!), for: .normal)
            */
        }
    }
    
    var autoHideSendButton: Bool = false {
        didSet {
            if autoHideSendButton == oldValue {
                return
            }
            self.myp_updateSendButtonsConstraints()
        }
    }
    
    private func shouldHideRightMoreButton() -> Bool {
        if self.rightMoreButtonImageName == nil || self.rightMoreButtonImageName == "" {
            return true
        }
        // we need this judge.
        // the rightMoreButton and sendButton do not show at the same time
        let text = self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > 0 {
            return true
        }
        return false
    }
    
    private func shouldHideSendButton() -> Bool {
        let text = self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if autoHideSendButton {
            if text.count == 0 {
                return true
            }
        }

        if self.rightMoreButtonImageName != nil && self.rightMoreButtonImageName != "" {
            if text.count == 0 {
                return true
            }
        }
        return false
    }
    
    private func shouldEnableSendButton() -> Bool {
        let text = self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return text.count > 0 && !self.isLimitExceeded ? true : false
    }
    
    /** The custom input accessory view, used as empty achor view to detect the keyboard frame. */
    override var inputAccessoryView: MYPInputAccessoryView {
        return inputAccessoryViewHelper
    }
    
    private var inputAccessoryViewHelper: MYPInputAccessoryView = {
        let acV = MYPInputAccessoryView(frame: .zero)
        acV.backgroundColor = .clear
        acV.isUserInteractionEnabled = false
        return acV
    }()
    
    /** true if animations should have bouncy effects. Default is false. */
    var bounces = false
    
    /** The inner padding to use when laying out content in the view.
     left: H:|-left-leftButton,
     right: H:sendButton-right-|,
     top: V:topDivider-top-textView,
     bottom: bottomDivider-bottom-|.
     Top is 0 to make a nice textView surface.
     Default is {0, 8, 8, 8}. */
    var contentInset: UIEdgeInsets {
        get {
            return UIEdgeInsets(top: self.contentTopMarginC.constant, left: self.contentLeftLeadingC.constant, bottom: self.contentBottomMarginC.constant, right: self.contentRightTrailingC.constant)
        }
        set {
            // do change the margin
            if self.contentInset == newValue {
                return
            }
            if self.contentInset.top != newValue.top {
                self.contentTopMarginC.constant = newValue.top
            }
            if self.contentInset.left != newValue.left {
                self.contentLeftLeadingC.constant = newValue.left
            }
            if self.contentInset.bottom != newValue.bottom {
                self.contentBottomMarginC.constant = newValue.bottom
            }
            if self.contentInset.right != newValue.right {
                self.contentRightTrailingC.constant = newValue.right
            }
        }
    }
    
    /** The minimum height based on the intrinsic content size's. */
    var minimumInputbarHeight: CGFloat {
        var minimumHeight = self.textView.intrinsicContentSize.height
        
        minimumHeight += self.topDividerHeightC.constant + self.contentInset.top + self.contentInset.bottom + self.bottomDividerHeightC.constant
        return minimumHeight
    }
    
    /** The most appropriate height calculated based on the amount of lines of text and other factors.
     We should not use appropriateHeight in any init settiing or loadView or viewDidLoad.
     We should use minimumInputbarheight when init setting and use appropriateHeight in post observer: textDidChange.
     since the line number of textView will not be 1 when init, it will be 32 or any larger.
     */
    var appropriateHeight: CGFloat {
        var height: CGFloat = 0.0
        let minimumHeight = self.minimumInputbarHeight
        
        //print("input bar view, minimumHeight: \(minimumHeight)")
        
        //print("input bar view, number of lines: \(self.textView.numberOfLines)")
        
        if self.textView.numberOfLines == 1 {
            height = minimumHeight
        }
        else if self.textView.numberOfLines < self.textView.maxNumberOfLines {
            height = self.myp_inputbarHeight(lineNumber: self.textView.numberOfLines)
        }
        else {
            height = self.myp_inputbarHeight(lineNumber: self.textView.maxNumberOfLines)
        }
        
        if height < minimumHeight {
            height = minimumHeight
        }
        
        return height
    }
    
    private func myp_inputbarHeight(lineNumber lines: Int) -> CGFloat {
        var height = self.textView.intrinsicContentSize.height
        height -= self.textView.font!.lineHeight
        height += self.textView.font!.lineHeight * CGFloat(lines)
        height += self.contentInset.top
        height += self.contentInset.bottom
        height += self.topDividerHeightC.constant
        height += self.bottomDividerHeightC.constant
        
        return height
    }
    
    /** The maximum character count allowed. Default is 0, which means limitless.*/
    var maxCharCount: Int = 0
    
    /** true if the maxmimum character count has been exceeded. readonly*/
    var isLimitExceeded: Bool {
        let text = self.textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if self.maxCharCount > 0 && text.count > self.maxCharCount {
            return true
        }
        return false
    }
    
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: self.minimumInputbarHeight)
    }
    
    override var backgroundColor: UIColor? {
        didSet {
            //do some
        }
    }
    
    override var tintColor: UIColor! {
        didSet {
            //do some
        }
    }
    
    var topDividerBackgroundColor: UIColor? {
        get {
            return self.topDivider.backgroundColor
        }
        set {
            self.topDivider.backgroundColor = newValue
        }
    }
    
    var bottomDividerBackgroundColor: UIColor? {
        get {
            return self.bottomDivider.backgroundColor
        }
        set {
            self.bottomDivider.backgroundColor = newValue
        }
    }
    
    //初始化时将xib中的view添加进来
    var contentView:UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        contentView = loadViewFromNib()
        addSubview(contentView)
        addConstraints()
        
        commonSetting()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentView = loadViewFromNib()
        addSubview(contentView)
        addConstraints()
        
        commonSetting()
    }
    
    init() {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        contentView = loadViewFromNib()
        addSubview(contentView)
        addConstraints()
        
        commonSetting()
    }
    
    private func commonSetting() {
        self.textView.textContainerInset = UIEdgeInsetsMake(8.0, 4.0, 8.0, 0.0)
        self.textView.maxNumberOfLines = MYPTextInputbarView.myp_defaultNumberOfLines()
        
        self.myp_initialActionButtonHeightAndWidth()
        
        self.previousOrigin = self.frame.origin
        
        self.myp_updateSendButtonsConstraints()
        
        self.myp_registerNotifications()
        
        self.layer.addObserver(self, forKeyPath: NSStringFromSelector(#selector(getter: CALayer.position)), options: [.new, .old], context: nil)
    }
    
    /** update action button's initial height and width*/
    private func myp_initialActionButtonHeightAndWidth() {
        self.topDividerHeightC.constant = MYPOnePixal
        self.bottomDividerHeightC.constant = MYPOnePixal
        
        let initialHeight = self.textView.intrinsicContentSize.height
        self.actionButtonHeightC.constant = initialHeight
        
        // first initial width and height
        self.leftButtonWidthC.constant = initialHeight
        self.rightButtonWidthC.constant = initialHeight
        self.rightMoreButtonWidthC.constant = initialHeight
        
        // then record the new size
        self.initialButtonMargin = self.textViewLeftLeadingC.constant
        self.initialButtonWidth = self.leftButtonWidthC.constant
        self.initialSendButtonWidth = self.sendButtonWidthC.constant
        
        // we must have this, otherwise we will get a wrong initial height of inputbar view
        // but we got a `EXC_BAD_ACCESS with code=2` bug when used in messageController
        //self.layoutIfNeeded()
    }
    
    /** update the rightMoreButton and sendButton constraints*/
    private func myp_updateSendButtonsConstraints() {
        if shouldHideRightMoreButton() {
            self.rightMoreButtonWidthC.constant = 0
        }
        else {
            self.rightMoreButtonWidthC.constant = self.initialButtonWidth
        }
        if shouldHideSendButton() {
            self.sendButtonWidthC.constant = 0
        }
        else {
            self.sendButtonWidthC.constant = self.initialSendButtonWidth
        }
    }
    
    private class func myp_defaultNumberOfLines() -> Int {
        if MYP_IS_IPAD {
            return 8
        }
        return 6
    }
    
    //加载xib
    func loadViewFromNib() -> UIView {
        let className = type(of: self)
        let bundle = Bundle(for: className)
        let name = NSStringFromClass(className).components(separatedBy: ".").last
        let nib = UINib(nibName: name!, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        
        return view
    }
    
    //设置contentView的约束
    private func addConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        var constraint = NSLayoutConstraint(item: contentView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: contentView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: contentView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        addConstraint(constraint)
    }
    
    private func myp_registerNotifications() {
        self.myp_unregisterNotifications()
        
        NotificationCenter.default.addObserver(self, selector: #selector(myp_textViewDidChangeText), name: Notification.Name.UITextViewTextDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(myp_textViewDidChangeContentSize(notification:)), name: Notification.Name.MYPTextInputTask.MYPTextViewContentSizeDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(myp_textViewDidChangeContentSizeCategory(notification:)), name: Notification.Name.UIContentSizeCategoryDidChange, object: nil)
    }
    
    private func myp_unregisterNotifications() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UITextViewTextDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.MYPTextInputTask.MYPTextViewContentSizeDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIContentSizeCategoryDidChange, object: nil)
    }
    
    //MARK: - Notification Events
    @objc
    private func myp_textViewDidChangeText(notification: Notification) {
        
        let textView = notification.object as! MYPTextView
        if textView != self.textView {
            return
        }
        
        if self.sendButton.isEnabled != self.shouldEnableSendButton() {
            self.sendButton.isEnabled = !self.sendButton.isEnabled
            let bgColor = self.sendButton.isEnabled ? self.sendButton.tintColor : UIColor.lightGray
            self.sendButton.backgroundColor = bgColor
        }
        
        self.myp_updateSendButtonsConstraints()
        
        let bounces = self.bounces && self.textView.isFirstResponder
        
        if self.window != nil {
            self.myp_animateLayoutIfNeeded(withBounce: bounces, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction], animations: nil)
        }
        else {
            self.layoutIfNeeded()
        }
    }
    
    @objc
    private func myp_textViewDidChangeContentSize(notification: Notification) {
        // do some
    }
    
    @objc
    private func myp_textViewDidChangeContentSizeCategory(notification: Notification) {
        if !self.textView.isDynamicTypeEnabled {
            return
        }
        self.layoutIfNeeded()
    }
    
    //MARK: - observers
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as? CALayer == self.layer && (keyPath == NSStringFromSelector(#selector(getter: CALayer.position))) {
            if previousOrigin != frame.origin {
                previousOrigin = frame.origin
                NotificationCenter.default.post(name: Notification.Name.MYPTextInputbarTask.MYPTextInputbarDidMoveNotification, object: self, userInfo: ["origin": NSValue(cgPoint: previousOrigin)])
            }
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    //MARK: - lifetime
    deinit {
        self.myp_unregisterNotifications()
        
        self.layer.removeObserver(self, forKeyPath: NSStringFromSelector(#selector(getter: CALayer.position)))
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}