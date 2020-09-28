import Foundation

public class ComponentAction {
    typealias NodeInfo = (actions: [ActionType: Any], component: AnyComponent)


    /// Starting action processing
    /// - Parameters:
    ///   - actionType: Type of action taken
    ///   - userInfo: Any additional information for action
    ///   - sender: Content view for component
    static public func invoke(_ actionType: ActionType, sender: UIView?, userInfo: [AnyHashable: Any]? = nil) {
        guard let view = sender,
            let cell = view.superview?.superview,
            let target = cell.superview,
            let adapter = adapterTarget(for: target),
            let indexPath = indexPath(for: cell, in: adapter),
            let nodeInfo = nodeInfo(for: indexPath, in: adapter),
            let actionComponent = nodeInfo.component.as(ComponentAnyActionable.self) else { return }

        var actionContent = AnyActionContent(view: view, component: nodeInfo.component, type: actionType,
                                             target: target, indexPath: indexPath, userInfo: userInfo)

        processChangeNode(component: nodeInfo.component, for: &actionContent, with: adapter)
        adapter.renderer?.actionsDelegate?.did(action: actionContent)
        actionContent.component = adapter.component(for: indexPath)
        actionComponent.call(actionContent, in: nodeInfo.actions)
    }

    // MARK: Private Methods
    private static func adapterTarget(for target: UIView) -> Adapter? {
        ((target as? UITableView)?.dataSource as? Adapter) ?? ((target as? UICollectionView)?.dataSource as? Adapter)
    }

    private static func indexPath(for cell: UIView, in adapter: Adapter) -> IndexPath? {
        (cell as? UITableViewComponentCell).flatMap(adapter.indexPath) ??
            (cell as? UICollectionViewComponentCell).flatMap(adapter.indexPath) ??
            (cell as? UITableViewComponentHeaderFooterView).flatMap(adapter.indexPath)
    }

    private static func nodeInfo(for indexPath: IndexPath, in adapter: Adapter) -> NodeInfo? {
        adapter.cellNode(for: indexPath).flatMap { ($0.actions, $0.component) } ??
            adapter.viewNode(for: indexPath).flatMap { ($0.actions, $0.component) }
    }

    private static func processChangeNode(component: AnyComponent, for actionContent: inout AnyActionContent, with adapter: Adapter) {
        guard let updatedComponent = component.as(ComponentUpdater.self)?.needChange(for: actionContent),
            let indexPath = actionContent.indexPath else { return }
        actionContent.component = updatedComponent
        if component.shouldContentUpdate(with: updatedComponent) {
            var data = adapter.data
            data.update(anyComponent: updatedComponent, for: indexPath)
            adapter.renderer?.render(data)
        } else {
            adapter.update(anyComponent: updatedComponent, for: indexPath)
        }
    }
}