import UIKit
import HSEthereumKit
import RxSwift

class SendController: UIViewController {
    private let disposeBag = DisposeBag()

    @IBOutlet weak var addressTextField: UITextField?
    @IBOutlet weak var amountTextField: UITextField?
    @IBOutlet weak var sendCoin: UIButton!
    @IBOutlet weak var gasPriceTextField: UITextField!

    var priority = FeePriority.medium

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Send"
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @IBAction func send(_ sender: Any) {
        guard Manager.shared.ethereumKit != nil else {
            return
        }

        guard let address = addressTextField?.text, !address.isEmpty else {
            show(error: "Empty Address")
            return
        }

        guard let amountString = amountTextField?.text, let amount = Decimal(string: amountString) else {
            show(error: "Empty or Non Integer Amount")
            return
        }

        let adapter: BaseAdapter

        if (sender as? UIButton) == sendCoin {
            adapter = Manager.shared.erc20Adapter
        } else {
            adapter = Manager.shared.ethereumAdapter
        }

        adapter.sendSingle(to: address, amount: amount)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] _ in
                    self?.showSuccess(address: address, amount: amount)
                }, onError: { [weak self] error in
                    self?.show(error: "Something conversion wrong: \(error)")
                })
                .disposed(by: disposeBag)
    }

    @IBAction func changePriority(sender: UISegmentedControl) {
        gasPriceTextField.isHidden = true

        switch sender.selectedSegmentIndex {
        case 0: priority = .lowest
        case 1: priority = .low
        case 2: priority = .medium
        case 3: priority = .high
        case 4: priority = .highest
        case 5:
            gasPriceTextField.isHidden = false
            fillPriority(with: gasPriceTextField.text)
        default: priority = .medium
        }
    }

    @IBAction func changeGasPrice(sender: UITextField) {
        fillPriority(with: sender.text)
    }

    func fillPriority(with text: String?) {
        if let gasPrice = Int(text ?? "") {
            priority = .custom(gasPriceInWei: gasPrice * 1_000_000_000)
        } else  {
            priority = .medium
        }
    }

    private func show(error: String) {
        let alert = UIAlertController(title: "Send Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func showSuccess(address: String, amount: Decimal) {
        addressTextField?.text = ""
        amountTextField?.text = ""

        let alert = UIAlertController(title: "Success", message: "\(amount.description) sent to \(address)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

}
