//
//  ViewController.swift
//  stockInform
//
//  Created by Mazur Aleksey on 02.02.2020.
//  Copyright © 2020 Mazur Aleksey. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var companyPicker: UIPickerView!
    @IBOutlet weak var loadBar: UIActivityIndicatorView!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var companyPriceLabel: UILabel!
    @IBOutlet weak var companyPriceChangeLabel: UILabel!
    @IBOutlet weak var logoImage: UIImageView!
    
    private lazy var companies = [
       "Apple": "AAPL",
       "Microsoft": "MSFT",
       "Google": "GOOG",
       "Amazon": "AMZN",
       "Facebook": "FB"
    ]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companies.keys.count
    }
    
     func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,  forComponent component: Int) ->
            String? {
    
            return Array(companies.keys)[row]
    }
    
     func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int,  inComponent component: Int) {
            print("didSelectRow")
            let selectedName = Array(companies.values)[row]
        
            companyNameLabel.text = "-"
            companySymbolLabel.text = "-"
            companyPriceLabel.text = "-"
            companyPriceChangeLabel.text = "-"
            logoImage.image = nil
        
            companyPriceChangeLabel.textColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 1)
            loadBar.startAnimating()
        
            requestQuote(for: selectedName)
            requestLogo(for: selectedName)
    }
    
    // Парсим список акций
    private func parseStockList(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard
                let stockArray = jsonObject as? [AnyObject] else {return print("Invalid JSON")}
            
            for stock in stockArray {
                let symbol = stock.value(forKey:"symbol") as? String
            }
        }
        catch{
            print("JSON parsing errro: " + error.localizedDescription)
        }
    }
    
    // парсим данные об акции
    private func parseQuote(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let symbol = json["symbol"] as? String,
                let latestPrice = json["latestPrice"] as? Double,
                let change = json["change"] as? Double else {return print("Invalid JSON")}
            
                DispatchQueue.main.async { [weak self] in
                    self?.displayStockChange(
                        companyName: companyName,
                        symbol: symbol,
                        latestPrice: latestPrice,
                        change: change)
                }
        }
        catch{
            print("JSON parsing errro: " + error.localizedDescription)
        }
    }
    
    // парсим url с лога акции
    private func parseLogo(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard
                let json = jsonObject as? [String: Any],
                let urlString = json["url"] as? String else {return print("Invalid JSON")}
                
                let url = URL(string: urlString)!
            
                DispatchQueue.main.async { [weak self] in
                    self?.downloadImage(from: url)
                }
        }
        catch{
            print("JSON parsing errro: " + error.localizedDescription)
        }
    }
    
    // Запрос списка акций
    private func requestStockList() {
        let token = "pk_6fcc4683392643f1a9158ab5da65590b"
        
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/market/collection/list?collectionName=mostactive&token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data {
                self.parseStockList(from: data)
            }
        }
    
        dataTask.resume()
    }
    
    // Запрос информации об акции
    private func requestQuote(for symbol: String) {
        let token = "pk_6fcc4683392643f1a9158ab5da65590b"
        let urlString = "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?&token=\(token)"
        guard let url = URL(string: urlString) else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let data = data,
                ( response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                    self?.parseQuote(from: data)
                }
            else {
                let alert = UIAlertController(title: "Network error?", message: "Failed to get stock information.", preferredStyle: .alert)

                
                DispatchQueue.main.async { [weak self] in
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in
                        self?.loadBar.stopAnimating()
                    }))
                    
                    self?.present(alert, animated: true)

                }
            }
            
        }
    
        dataTask.resume()
    }
    
    // Запрос url лого акции
    private func requestLogo(for symbol: String) {
        let token = "pk_6fcc4683392643f1a9158ab5da65590b"
        let urlString = "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?&token=\(token)"
        guard let url = URL(string: urlString) else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let data = data,
                ( response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                    self?.parseLogo(from: data)
                }
            else {
                print("NetworkError!")
            }
            
        }
    
        dataTask.resume()
    }
    
    // загрузить лого
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    // отобразить лого
    func downloadImage(from url: URL) {
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            DispatchQueue.main.async() {
                self.logoImage.image = UIImage(data: data)
            }
        }
    }
    
    private func displayStockChange(companyName: String, symbol: String, latestPrice: Double, change: Double){
        companyNameLabel.text = companyName
        companySymbolLabel.text = symbol
        companyPriceLabel.text = "\(latestPrice) $"
        companyPriceChangeLabel.text = "\(change) $"
        
        if(change>0) {
            companyPriceChangeLabel.textColor = UIColor.init(red: 0, green: 255, blue: 0, alpha: 1)
        } else {
            if(change<0) {
                companyPriceChangeLabel.textColor = UIColor.init(red: 255, green: 0, blue: 0, alpha: 1)
            } else {
                companyPriceChangeLabel.textColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 1)
            }
        }
        
        loadBar.stopAnimating()
    }
    
    private func updateDisplayInfo(companyName: String){
        companyNameLabel.text = companyName
        loadBar.stopAnimating()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        companyPicker.dataSource = self
        companyPicker.delegate = self
        loadBar.startAnimating()
//        requestStockList()
        
        
        let selectedRow = companyPicker.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        loadBar.startAnimating()
        requestQuote(for: selectedSymbol)
        requestLogo(for: selectedSymbol)
    }
}

