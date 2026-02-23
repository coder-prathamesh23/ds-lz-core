# azureml-workspace (optional add-on)

This is a reserved add-on module location for Azure Machine Learning (AML) resources.

**Intentionally minimal:** the Data Science core landing zone stays simple (network + connectivity + baseline shared services).
AML workspace / compute / private endpoint patterns can be implemented here later.

If you are not implementing AML yet, you can safely delete:
- `modules/addons/azureml-workspace`
- `stacks/addons/azureml-workspace`
