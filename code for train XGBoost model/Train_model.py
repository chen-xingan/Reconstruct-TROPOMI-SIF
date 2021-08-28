##### train XGBoost to predict SIF
####

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import OneHotEncoder
from sklearn.model_selection import GridSearchCV
from sklearn.metrics import mean_absolute_error
from sklearn.metrics import r2_score
import os
import xgboost as xgb
import scipy.io as sio
import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns
import time


data = pd.read_csv('./train_data.csv')
data['IGBP'] = data['IGBP'].astype(str)

# Dividing features and target
X = data.drop(columns = ['SIF'], axis = 1)
y = data[['SIF']]

# Categorical variables
category_feature_mask = X.dtypes == object
category_cols = X.columns[category_feature_mask].tolist()
X_categorical = X[category_cols].copy()
X_continuous = X.drop(category_cols, axis = 1)

# Continuous variables normalization
std = StandardScaler()
X_continuous_data = std.fit_transform(X_continuous)
X_continuous_df = pd.DataFrame(X_continuous_data, columns = X_continuous.columns)

# OneHotEncoder
enc = OneHotEncoder()
enc.fit(X_categorical)
X_categorical_data = enc.transform(X_categorical).toarray()
X_categorical_df = pd.DataFrame(X_categorical_data, columns = [enc.get_feature_names()])
X_new = pd.concat([X_continuous_df, X_categorical_df],axis=1)

# Split training set and test set
X_train, X_test, y_train, y_test = train_test_split(X_new, y, test_size=0.2, shuffle = True, random_state=1729)

# n_estimators
cv_params = {'n_estimators': [1000, 1500, 2000, 2500, 3000, 3500, 4000]}
other_params = {'learning_rate': 0.1, 'n_estimators': 1500, 'max_depth': 5, 'min_child_weight': 1, 'seed': 0,
                'subsample': 0.8, 'colsample_bytree': 0.8, 'gamma': 0, 'reg_alpha': 0, 'reg_lambda': 1, 'tree_method' : 'gpu_hist'}
fit_params = {'early_stopping_rounds': 50}
model = xgb.XGBRegressor(**other_params)
optimized_GBM = GridSearchCV(estimator=model, param_grid=cv_params, scoring='r2', cv=2, verbose=1, n_jobs=4, fit_params=fit_params)
optimized_GBM.fit(X_train, y_train)
evalute_result = optimized_GBM.cv_results_
print('each_iteration:{0}'.format(evalute_result))
print('best_params：{0}'.format(optimized_GBM.best_params_))
print('best_score:{0}'.format(optimized_GBM.best_score_))

# min_child_weight and max_depth
cv_params = {'max_depth': [3, 4, 5, 6, 7, 8, 9, 10], 'min_child_weight': [1, 2, 3, 4, 5, 6]}
other_params = {'learning_rate': 0.1, 'n_estimators': 2500, 'max_depth': 5, 'min_child_weight': 1, 'seed': 0,
                'subsample': 0.8, 'colsample_bytree': 0.8, 'gamma': 0, 'reg_alpha': 0, 'reg_lambda': 1, 'tree_method' : 'gpu_hist'}
model = xgb.XGBRegressor(**other_params)
optimized_GBM = GridSearchCV(estimator=model, param_grid=cv_params, scoring='r2', cv=2, verbose=1, n_jobs=4)
optimized_GBM.fit(X_train, y_train)
evalute_result = optimized_GBM.cv_results_
print('each_iteration:{0}'.format(evalute_result))
print('best_params：{0}'.format(optimized_GBM.best_params_))
print('best_score:{0}'.format(optimized_GBM.best_score_))

# learning_rate
cv_params = {'learning_rate': [0.01, 0.05, 0.07, 0.1, 0.2]}
other_params = {'learning_rate': 0.1, 'n_estimators': 550, 'max_depth': 5, 'min_child_weight': 1, 'seed': 0,
                'subsample': 0.8, 'colsample_bytree': 0.8, 'gamma': 0, 'reg_alpha': 0, 'reg_lambda': 1, 'tree_method' : 'gpu_hist'}
model = xgb.XGBRegressor(**other_params)
optimized_GBM = GridSearchCV(estimator=model, param_grid=cv_params, scoring='r2', cv=2, verbose=1, n_jobs=4)
optimized_GBM.fit(X_train, y_train)
evalute_result = optimized_GBM.cv_results_
print('each_iteration:{0}'.format(evalute_result))
print('best_params：{0}'.format(optimized_GBM.best_params_))
print('best_score:{0}'.format(optimized_GBM.best_score_))

# final model
XGBR = xgb.XGBRegressor(n_estimators=3000,
                        max_depth=9,
                        min_child_weight=5,
                        learning_rate=0.1,
                        tree_method='gpu_hist')
XGBR.fit(X_train, y_train)
start = time.clock()
y_pred = XGBR.predict(X_test)
elapsed = (time.clock() - start)
print("Time used:", elapsed)

print(f'RMSE : {np.sqrt(mean_absolute_error(y_test, y_pred))}')
print(f'R2 : {r2_score(y_test, y_pred)}')

import joblib
joblib.dump(XGBR,'./xgb_SIF.pkl')