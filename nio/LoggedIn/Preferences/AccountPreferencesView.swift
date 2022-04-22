//
//  AccountPreferencesView.swift
//  Nio
//
//  Created by Finn Behrens on 21.04.22.
//

import MatrixClient
import NioKit
import SwiftUI

struct AccountPreferencesView: View {
    @EnvironmentObject var account: NioAccount
    @EnvironmentObject var deepLinker: DeepLinker
    @Environment(\.dismiss) private var dismiss

    @State private var working = false
    @State private var newAccountName: String = ""
    @State private var newDisplayName: String = ""

    var body: some View {
        List {
            Section {
                // Profile name
                HStack {
                    Text("Account Name")
                    Spacer(minLength: 10)

                    TextField("Account Name", text: $newAccountName)
                        .multilineTextAlignment(.trailing)
                }

                // Matrix Display name
                HStack {
                    Text("Display Name")
                    Spacer(minLength: 10)

                    TextField("Display Name", text: $newDisplayName)
                        .multilineTextAlignment(.trailing)
                }

                // TODO:
                Text("Change Password")
            } header: {
                Text("USER SETTINGS")
            }

            Section {
                NavigationLink(
                    "Security",
                    destination: {
                        AccountPreferencesSecurityView()
                            .environmentObject(account)
                    }
                )
            } header: {
                Text("Security")
            }
        }
        .navigationTitle(account.info.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if working {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Button("Save", action: self.save)
                        // TODO: some way to see if there is something to save
                        .disabled(false)
                }
            }
        }
        .onAppear {
            self.newAccountName = account.info.name
            self.newDisplayName = account.info.displayName ?? ""
        }
    }

    private func save() {
        working = true
        Task(priority: .userInitiated) {
            print("save")
            do {
                try await self.saveDisplayName()
                try await self.saveAccountName()

                DispatchQueue.main.async {
                    self.working = false
                    self.dismiss()
                }
            } catch {
                NioAccountStore.logger
                    .warning("Failed to save user config for user \(self.account.info.name) (\(self.account.mxID)")
                working = false
            }
        }
    }

    private func saveDisplayName() async throws {
        if account.info.displayName != newDisplayName {
            NioAccountStore.logger.debug("Applying DisplayName")
            account.info.displayName = newDisplayName

            // TODO: use MatrixUserIdentifer instead of stringified version
            try await account.core.client.setDisplayName(newDisplayName, userID: account.info.FQMXID)
        }
    }

    private func saveAccountName() async throws {
        if account.info.name != newAccountName {
            NioAccountStore.logger.debug("Saving account name")
            account.info.name = newAccountName
            try await account.updateInfo()
        }
    }
}

struct AccountPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        AccountPreferencesView()
    }
}
