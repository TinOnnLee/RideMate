/*
 * Copyright (c) 2015 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

class EventListTableViewController: UITableViewController {

    // MARK: Constants
    let listToUsers = "ListToUsers"
  
    // MARK: Properties
    var items: [EventItem] = []
    let eventRef = FIRDatabase.database().reference(withPath: "event-items")
    let usersRef = FIRDatabase.database().reference(withPath: "online")
    var user: User!
    var userCountBarButtonItem: UIBarButtonItem!
  
    // MARK: UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsMultipleSelectionDuringEditing = false
        userCountBarButtonItem = UIBarButtonItem(title: "1",
                                             style: .plain,
                                             target: self,
                                             action: #selector(userCountButtonDidTouch))
        userCountBarButtonItem.tintColor = UIColor.white
        navigationItem.leftBarButtonItem = userCountBarButtonItem
        usersRef.observe(.value, with: { snapshot in
            if snapshot.exists() {
                self.userCountBarButtonItem?.title = "Online - " + snapshot.childrenCount.description
            } else {
                self.userCountBarButtonItem?.title = "Online - 0"
            }
        })
    
        eventRef.queryOrdered(byChild: "completed").observe(.value, with: { snapshot in
            var newItems: [EventItem] = []
            for item in snapshot.children {
                let eventItem = EventItem(snapshot: item as! FIRDataSnapshot)
                newItems.append(eventItem)
            }
            self.items = newItems
            self.tableView.reloadData()
        })
        if ((Shared.shared.successfulLogin == true)&&(Shared.shared.registrationMode == true)) {
            self.printMessage(name: "Registration successful.")
        }
        FIRAuth.auth()!.addStateDidChangeListener { auth, user in
            guard let user = user else { return }
            self.user = User(authData: user)
            let currentUserRef = self.usersRef.child(self.user.uid)
            currentUserRef.setValue(self.user.email)
            currentUserRef.onDisconnectRemoveValue()
        }
    }
  
    // MARK: UITableView Delegate methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        let eventItem = items[indexPath.row]
        cell.textLabel?.text = eventItem.name
        cell.detailTextLabel?.text = eventItem.addedByUser
        toggleCellCheckbox(cell, isCompleted: eventItem.completed)
        return cell
    }
  
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
  
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let eventItem = items[indexPath.row]
            eventItem.ref?.removeValue()
        }
    }
  
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let eventItem = items[indexPath.row]
        let toggledCompletion = !eventItem.completed
        toggleCellCheckbox(cell, isCompleted: toggledCompletion)
        eventItem.ref?.updateChildValues([ "completed": toggledCompletion ])
    }
  
    func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
        if !isCompleted {
            cell.accessoryType = .none
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.textColor = UIColor.black
        } else {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = UIColor.gray
            cell.detailTextLabel?.textColor = UIColor.gray
        }
    }
  
    // MARK: Add Item
  
    @IBAction func addButtonDidTouch(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Event Item",
                                  message: "Add an Item",
                                  preferredStyle: .alert)
    
        let saveAction = UIAlertAction(title: "Save",
                                    style: .default) { _ in
                                    guard let textField = alert.textFields?.first,
                                      let text = textField.text else { return }
                                   let eventItem = EventItem(name: text,
                                                                  addedByUser: self.user.email,
                                                                  completed: false)
                                    let eventItemRef = self.eventRef.child(text.lowercased())
                                    eventItemRef.setValue(eventItem.toAnyObject())
        }
    
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
    
        present(alert, animated: true, completion: nil)
    }
  
    func userCountButtonDidTouch() {
        performSegue(withIdentifier: listToUsers, sender: nil)
    }
    func printMessage(name:String) {
        let alert = UIAlertController(title: "Alert", message: name, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil )
    }
    
}
