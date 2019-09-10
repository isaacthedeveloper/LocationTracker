//
//  CategoryPickerViewController.swift
//  Locations
//
//  Created by Isaac Ballas on 2019-09-02.
//  Copyright © 2019 Isaacballas. All rights reserved.
//

import UIKit

class CategoryPickerViewController: UITableViewController {
  var selectedCategoryName = ""
  
  let categories = [
    "No Category",
    "Apple Store",
    "Bar",
    "Bookstore",
    "Club",
    "Grocery Store",
    "Historic Building",
    "House",
    "Icecream Vendor",
    "Landmark",
    "Park"]
  
  /* When the screen opens, there is a checkmark next to the selected category,from the selectedCategoryName Property,
   which is filled in when the user segues to the screen. When the user taps a row, the checkmark needs to move to this new row. To do this you need a rowNumber, you cant use selected category name since its a string, so selectedIndexPath is a good alternative.
   That happens in viewDidLoad(). You loop through the array of categories and compare the name of each category to selectedCategoryName. If they match, you create an index-path object and store it in the selectedIndexPath variable. Once a match is found, you can break out of the loop because there’s no point in looping through the rest of the categories.
 */
  var selectedIndexPath = IndexPath()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    for i in 0..<categories.count {
      if categories[i] == selectedCategoryName {
        selectedIndexPath = IndexPath(row: i, section: 0)
        break
      }
    }
  }
  
  // MARK:- Table View Delegates
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return categories.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",for: indexPath)
      
      let categoryName = categories[indexPath.row]
      cell.textLabel!.text = categoryName
      
      if categoryName == selectedCategoryName {
        cell.accessoryType = .checkmark
      } else {
        cell.accessoryType = .none
      }
      return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.row != selectedIndexPath.row {
      if let newCell = tableView.cellForRow(at: indexPath) {
        newCell.accessoryType = .checkmark
      }
      if let oldCell = tableView.cellForRow(
        at: selectedIndexPath) {
        oldCell.accessoryType = .none
      }
      selectedIndexPath = indexPath
    }
  }
  
  // MARK:- Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "PickedCategory" {
      let cell = sender as! UITableViewCell
      if let indexPath = tableView.indexPath(for: cell) {
        selectedCategoryName = categories[indexPath.row]
      }
    }
  }
  
}


