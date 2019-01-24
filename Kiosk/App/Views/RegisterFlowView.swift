import UIKit
import ORStackView
import RxSwift

class RegisterFlowView: ORStackView {

    let highlightedIndex: Variable<RegistrationIndex?> = Variable(nil)
    let tappedIndex: Variable<RegistrationIndex?> = Variable(nil)

    lazy var appSetup: AppSetup = .sharedState
    lazy var sale: Sale = appDelegate().sale

    var details: BidDetails? {
        didSet {
            update()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .white
        bottomMarginHeight = CGFloat(NSNotFound)
        updateConstraints()
    }

    fileprivate struct SubViewParams {
        let title: String
        let getters: Array<(NewUser) -> String?>
        let index: RegistrationIndex
    }

    fileprivate lazy var subViewParams: Array<SubViewParams> = {
        return [
            sale.bypassCreditCardRequirement ? [SubViewParams(title: "Name", getters: [{ $0.name.value }], index: .nameVC)] : [],
            [SubViewParams(title: "Mobile", getters: [{ $0.phoneNumber.value }], index: .mobileVC)],
            [SubViewParams(title: "Email", getters: [{ $0.email.value }], index: .emailVC)],
            [SubViewParams(title: "Postal/Zip", getters: [{ $0.zipCode.value }], index: .zipCodeVC)].filter { _ in self.appSetup.needsZipCode },
            sale.bypassCreditCardRequirement ? [] : [SubViewParams(title: "Credit Card", getters: [{ $0.creditCardName.value }, { $0.creditCardType.value }], index: .creditCardVC)]
        ].flatMap {$0}
    }()

    func update() {
        let user = details!.newUser

        removeAllSubviews()
        for (i, subViewParam) in subViewParams.enumerated() {
            let itemView = ItemView(frame: bounds, index: subViewParam.index)
            itemView.createTitleViewWithTitle(subViewParam.title)

            addSubview(itemView, withTopMargin: "10", sideMargin: "0")

            if let value = (subViewParam.getters.compactMap { $0(user) }.first) {
                itemView.createInfoLabel(value)

                let button = itemView.createJumpToButtonAtIndex(i)
                button.addTarget(self, action: #selector(pressed(_:)), for: .touchUpInside)

                itemView.constrainHeight("44")
            } else {
                itemView.constrainHeight("20")
            }

            if let index = highlightedIndex.value, index.shouldHightlight(subViewParam.index) {
                itemView.highlight()
            }
        }

        let spacer = UIView(frame: bounds)
        spacer.setContentHuggingPriority(UILayoutPriority(rawValue: 12), for: .horizontal)
        addSubview(spacer, withTopMargin: "0", sideMargin: "0")

        bottomMarginHeight = 0
    }

    @objc func pressed(_ sender: UIButton!) {
        guard let itemView = sender.superview as? ItemView else { return }
        if itemView.index == .emailVC {
            // If the user is modifying their email, make them re-enter their password too (since it doesn't have its own SubViewParam)
            details?.newUser.password.value = nil
        }
        tappedIndex.value = itemView.index // The RegistrationViewController will take care of updating highlightedIndex.value
    }

    class ItemView : UIView {

        var titleLabel: UILabel?
        let index: RegistrationIndex

        init(frame: CGRect, index: RegistrationIndex) {
            self.index = index
            super.init(frame: frame)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError() // Not expected to happen, but compiler.
        }

        func highlight() {
            titleLabel?.textColor = .artsyPurpleRegular()
        }

        func createTitleViewWithTitle(_ title: String)  {
            let label = UILabel(frame: bounds)
            label.font = UIFont.sansSerifFont(withSize: 16)
            label.text = title.uppercased()
            titleLabel = label

            addSubview(label)
            label.constrainWidth(to: self, predicate: "0")
            label.alignLeadingEdge(with: self, predicate: "0")
            label.alignTopEdge(with: self, predicate: "0")
        }

        func createInfoLabel(_ info: String) {
            let label = UILabel(frame: bounds)
            label.font = UIFont.serifFont(withSize: 16)
            label.text = info

            addSubview(label)
            label.constrainWidth(to: self, predicate: "-52")
            label.alignLeadingEdge(with: self, predicate: "0")
            label.constrainTopSpace(to: titleLabel!, predicate: "8")
        }

        func createJumpToButtonAtIndex(_ index: NSInteger) -> UIButton {
            let button = UIButton(type: .custom)
            button.tag = index
            button.setImage(UIImage(named: "edit_button"), for: .normal)
            button.isUserInteractionEnabled = true
            button.isEnabled = true

            addSubview(button)
            button.alignTopEdge(with: self, predicate: "0")
            button.alignTrailingEdge(with: self, predicate: "0")
            button.constrainWidth("36")
            button.constrainHeight("36")
            
            return button

        }
    }
}
